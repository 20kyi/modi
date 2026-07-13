import SwiftUI

// MARK: - PremiumManager

/// MODI+ 프리미엄 상태를 관리합니다. 실제 구독 연동 전까지 개발자용 토글로 상태를 시뮬레이션합니다.
@Observable
@MainActor
final class PremiumManager {

    static let shared = PremiumManager()

    private(set) var isDeveloperPremiumEnabled: Bool

    /// 앱 전역에서 참조하는 프리미엄 활성 여부입니다.
    var isPremium: Bool {
        isDeveloperPremiumEnabled
    }

    /// StoreKit 연동 시에도 동일한 이름으로 참조할 수 있는 프리미엄 여부입니다.
    var hasPremium: Bool {
        isPremium
    }

    /// 무료 사용자가 만들 수 있는 커스텀 컬렉션 최대 개수입니다.
    static let freeCustomCollectionLimit = 1

    /// 커스텀 컬렉션(`collectionType == .custom`) 생성 가능 여부를 판단합니다.
    func canCreateCustomCollection(currentCount: Int) -> Bool {
        hasPremium || currentCount < Self.freeCustomCollectionLimit
    }

    private let storage: UserDefaults

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

    static let mock = PremiumManager(storage: UserDefaults(suiteName: "premium-manager-mock")!)
}
