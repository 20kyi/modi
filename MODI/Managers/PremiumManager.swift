import StoreKit
import SwiftUI

// MARK: - PremiumManager

/// MODI+ 프리미엄 상태를 관리합니다.
@Observable
@MainActor
final class PremiumManager {

    static let shared = PremiumManager()

    private(set) var isDeveloperPremiumEnabled: Bool
    private(set) var isStorePremiumActive = false
    private(set) var products: [Product] = []
    private(set) var isLoadingProducts = false
    private(set) var isPurchasing = false
    private(set) var purchaseErrorMessage: String?

    /// 앱 전역에서 참조하는 프리미엄 활성 여부입니다.
    var isPremium: Bool {
        isDeveloperPremiumEnabled || isStorePremiumActive
    }

    /// StoreKit 연동 후에도 동일한 이름으로 참조할 수 있는 프리미엄 여부입니다.
    var hasPremium: Bool {
        isPremium
    }

    enum ProductID {
        static let monthly = "com.storybuild.modiapp.plus.monthly"
        static let annual = "com.storybuild.modiapp.plus.annual"
        static let lifetime = "com.storybuild.modiapp.plus.lifetime"

        static let all: Set<String> = [
            monthly,
            annual,
            lifetime,
        ]
    }

    /// 무료 사용자가 만들 수 있는 커스텀 컬렉션 최대 개수입니다.
    static let freeCustomCollectionLimit = 1

    /// 무료 사용자의 하루 미션 변경 최대 횟수입니다.
    static let freeMissionChangeLimit = 1

    /// MODI+ 사용자의 하루 미션 변경 최대 횟수입니다.
    static let premiumMissionChangeLimit = 3

    /// 커스텀 컬렉션(`collectionType == .custom`) 생성 가능 여부를 판단합니다.
    func canCreateCustomCollection(currentCount: Int) -> Bool {
        hasPremium || currentCount < Self.freeCustomCollectionLimit
    }

    /// 컬렉션 목록에서 사용자 생성 커스텀 컬렉션 개수를 계산합니다.
    /// 시스템 기본 컬렉션은 제외하고 `collectionType == .custom`만 집계합니다.
    func customCollectionCount(in collections: [MODICollection]) -> Int {
        collections.filter { $0.collectionType == .custom }.count
    }

    /// 전체 컬렉션 목록 기준으로 커스텀 컬렉션 생성 가능 여부를 판단합니다.
    func canCreateCustomCollection(in collections: [MODICollection]) -> Bool {
        canCreateCustomCollection(currentCount: customCollectionCount(in: collections))
    }

    /// 기존 커스텀 컬렉션에 새 기록(사진)을 추가할 수 있는지 판단합니다.
    /// 컬렉션 컨텍스트가 없을 때는 보수적으로 무료 사용자를 제한합니다.
    func canAddRecordToCustomCollection() -> Bool {
        hasPremium
    }

    /// 무료 사용자의 기본 커스텀 슬롯(가장 먼저 만든 컬렉션)을 반환합니다.
    func freeCustomCollectionSlotID(in collections: [MODICollection]) -> UUID? {
        collections
            .filter { $0.collectionType == .custom }
            .sorted {
                if $0.createdAt == $1.createdAt {
                    return $0.id.uuidString < $1.id.uuidString
                }
                return $0.createdAt < $1.createdAt
            }
            .first?
            .id
    }

    /// 특정 커스텀 컬렉션에 기록 추가 가능 여부를 판단합니다.
    /// 무료 사용자는 "가장 먼저 만든 커스텀 컬렉션" 1개에만 추가할 수 있습니다.
    func canAddRecordToCustomCollection(
        _ collection: MODICollection,
        allCollections: [MODICollection]
    ) -> Bool {
        guard collection.collectionType == .custom else { return true }
        guard !hasPremium else { return true }
        return freeCustomCollectionSlotID(in: allCollections) == collection.id
    }

    /// 컬렉션 타입별 기록 추가 가능 여부를 판단합니다.
    /// 시스템 컬렉션은 항상 허용, 커스텀 컬렉션은 `canAddRecordToCustomCollection`을 따릅니다.
    func canAddRecord(to collectionType: CollectionType) -> Bool {
        switch collectionType {
        case .system:
            true
        case .custom:
            canAddRecordToCustomCollection()
        }
    }

    func canAddRecord(to collection: MODICollection) -> Bool {
        canAddRecord(to: collection.collectionType)
    }

    func canAddRecord(to collection: MODICollection, allCollections: [MODICollection]) -> Bool {
        switch collection.collectionType {
        case .system:
            true
        case .custom:
            canAddRecordToCustomCollection(collection, allCollections: allCollections)
        }
    }

    /// 오늘의 미션 변경 가능 여부를 판단합니다.
    func canChangeMission(currentCount: Int) -> Bool {
        let limit = hasPremium ? Self.premiumMissionChangeLimit : Self.freeMissionChangeLimit
        return currentCount < limit
    }

    private let storage: UserDefaults
    private var transactionUpdatesTask: Task<Void, Never>?

    private enum StorageKeys {
        static let developerPremiumEnabled = "settings.premium.developerEnabled"
    }

    init(storage: UserDefaults = .standard) {
        self.storage = storage
        isDeveloperPremiumEnabled = storage.bool(forKey: StorageKeys.developerPremiumEnabled)
    }

    func setDeveloperPremiumEnabled(_ isEnabled: Bool) {
        guard isDeveloperPremiumEnabled != isEnabled else { return }
        isDeveloperPremiumEnabled = isEnabled
        storage.set(isEnabled, forKey: StorageKeys.developerPremiumEnabled)
    }

    func startStoreKitObservation() {
        guard transactionUpdatesTask == nil else { return }

        transactionUpdatesTask = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self else { return }
                await self.handleTransactionUpdate(result)
            }
        }
    }

    func loadProducts() async {
        guard products.isEmpty, !isLoadingProducts else { return }

        isLoadingProducts = true
        purchaseErrorMessage = nil

        do {
            let loadedProducts = try await Product.products(for: ProductID.all)
            products = loadedProducts.sorted { lhs, rhs in
                productSortOrder(lhs.id) < productSortOrder(rhs.id)
            }
        } catch {
            purchaseErrorMessage = "상품 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요."
        }

        isLoadingProducts = false
    }

    func product(for productID: String) -> Product? {
        products.first { $0.id == productID }
    }

    func purchase(productID: String) async {
        if products.isEmpty {
            await loadProducts()
        }

        guard let product = product(for: productID) else {
            purchaseErrorMessage = "선택한 상품을 찾을 수 없어요. App Store Connect 설정을 확인해주세요."
            return
        }

        isPurchasing = true
        purchaseErrorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verificationResult):
                let transaction = try checkVerified(verificationResult)
                await refreshPurchasedProducts()
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                purchaseErrorMessage = "결제가 대기 중이에요. 승인 후 MODI+가 활성화됩니다."
            @unknown default:
                purchaseErrorMessage = "결제를 완료하지 못했어요. 잠시 후 다시 시도해주세요."
            }
        } catch {
            purchaseErrorMessage = "결제를 완료하지 못했어요. 잠시 후 다시 시도해주세요."
        }

        isPurchasing = false
    }

    func restorePurchases() async {
        isPurchasing = true
        purchaseErrorMessage = nil

        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()

            if !isStorePremiumActive {
                purchaseErrorMessage = "복원할 MODI+ 구매 내역을 찾지 못했어요."
            }
        } catch {
            purchaseErrorMessage = "구매 복원에 실패했어요. 잠시 후 다시 시도해주세요."
        }

        isPurchasing = false
    }

    func refreshPurchasedProducts() async {
        var hasActiveEntitlement = false

        for await result in StoreKit.Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard ProductID.all.contains(transaction.productID) else { continue }
            guard transaction.revocationDate == nil else { continue }

            if let expirationDate = transaction.expirationDate {
                hasActiveEntitlement = expirationDate > Date()
            } else {
                hasActiveEntitlement = true
            }

            if hasActiveEntitlement {
                break
            }
        }

        isStorePremiumActive = hasActiveEntitlement
    }

    func clearPurchaseErrorMessage() {
        purchaseErrorMessage = nil
    }

    private func handleTransactionUpdate(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard let transaction = try? checkVerified(result) else { return }
        await refreshPurchasedProducts()
        await transaction.finish()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            safe
        case .unverified:
            throw StoreKitError.notVerified
        }
    }

    private func productSortOrder(_ productID: String) -> Int {
        switch productID {
        case ProductID.monthly:
            0
        case ProductID.annual:
            1
        case ProductID.lifetime:
            2
        default:
            3
        }
    }

    static let mock = PremiumManager(storage: UserDefaults(suiteName: "premium-manager-mock")!)
}

private enum StoreKitError: Error {
    case notVerified
}
