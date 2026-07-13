import Foundation
import Testing
@testable import MODI

@MainActor
struct PremiumEntitlementTests {

    @Test func freeUserCanCreateCustomCollectionWhenCountIsZero() {
        let storage = UserDefaults(suiteName: "premium-entitlement-free-zero")!
        storage.removePersistentDomain(forName: "premium-entitlement-free-zero")

        let manager = PremiumManager(storage: storage)
        manager.setDeveloperPremiumEnabled(false)

        #expect(manager.hasPremium == false)
        #expect(manager.canCreateCustomCollection(currentCount: 0) == true)
    }

    @Test func freeUserCannotCreateCustomCollectionWhenCountIsOne() {
        let storage = UserDefaults(suiteName: "premium-entitlement-free-one")!
        storage.removePersistentDomain(forName: "premium-entitlement-free-one")

        let manager = PremiumManager(storage: storage)
        manager.setDeveloperPremiumEnabled(false)

        #expect(manager.canCreateCustomCollection(currentCount: 1) == false)
    }

    @Test func premiumUserCanCreateCustomCollectionWhenCountIsOne() {
        let storage = UserDefaults(suiteName: "premium-entitlement-premium-one")!
        storage.removePersistentDomain(forName: "premium-entitlement-premium-one")

        let manager = PremiumManager(storage: storage)
        manager.setDeveloperPremiumEnabled(true)

        #expect(manager.hasPremium == true)
        #expect(manager.canCreateCustomCollection(currentCount: 1) == true)
    }

    @Test func premiumUserCanCreateManyCustomCollections() {
        let storage = UserDefaults(suiteName: "premium-entitlement-premium-many")!
        storage.removePersistentDomain(forName: "premium-entitlement-premium-many")

        let manager = PremiumManager(storage: storage)
        manager.setDeveloperPremiumEnabled(true)

        #expect(manager.canCreateCustomCollection(currentCount: 10) == true)
    }

    @Test func freeCustomCollectionLimitIsOne() {
        #expect(PremiumManager.freeCustomCollectionLimit == 1)
    }

    @Test func freeUserCanAddRecordToOldestCustomCollectionSlot() {
        let storage = UserDefaults(suiteName: "premium-entitlement-free-custom-record")!
        storage.removePersistentDomain(forName: "premium-entitlement-free-custom-record")

        let manager = PremiumManager(storage: storage)
        manager.setDeveloperPremiumEnabled(false)

        let oldestCollection = MODICollection(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000001")!,
            title: "가장 오래된 컬렉션",
            emoji: "☕️",
            type: .custom,
            createdAt: Date(timeIntervalSince1970: 1_000)
        )
        let newerCollection = MODICollection(
            id: UUID(uuidString: "B0000000-0000-0000-0000-000000000002")!,
            title: "최근 컬렉션",
            emoji: "🎵",
            type: .custom,
            createdAt: Date(timeIntervalSince1970: 2_000)
        )
        let allCollections = [newerCollection, oldestCollection]

        #expect(manager.freeCustomCollectionSlotID(in: allCollections) == oldestCollection.id)
        #expect(manager.canAddRecord(to: oldestCollection, allCollections: allCollections) == true)
        #expect(manager.canAddRecord(to: newerCollection, allCollections: allCollections) == false)
    }

    @Test func freeUserCanAddRecordToSystemCollection() {
        let storage = UserDefaults(suiteName: "premium-entitlement-free-system-record")!
        storage.removePersistentDomain(forName: "premium-entitlement-free-system-record")

        let manager = PremiumManager(storage: storage)
        manager.setDeveloperPremiumEnabled(false)

        #expect(manager.canAddRecord(to: .system) == true)
    }

    @Test func premiumUserCanAddRecordToCustomCollection() {
        let storage = UserDefaults(suiteName: "premium-entitlement-premium-custom-record")!
        storage.removePersistentDomain(forName: "premium-entitlement-premium-custom-record")

        let manager = PremiumManager(storage: storage)
        manager.setDeveloperPremiumEnabled(true)

        let customA = MODICollection(title: "A", emoji: "🍎", type: .custom)
        let customB = MODICollection(title: "B", emoji: "🍋", type: .custom)
        let allCollections = [customA, customB]

        #expect(manager.canAddRecordToCustomCollection() == true)
        #expect(manager.canAddRecord(to: .custom) == true)
        #expect(manager.canAddRecord(to: customA, allCollections: allCollections) == true)
        #expect(manager.canAddRecord(to: customB, allCollections: allCollections) == true)
    }

    @Test func customCollectionCountExcludesSystemCollections() {
        let storage = UserDefaults(suiteName: "premium-entitlement-custom-count")!
        storage.removePersistentDomain(forName: "premium-entitlement-custom-count")

        let manager = PremiumManager(storage: storage)
        manager.setDeveloperPremiumEnabled(false)

        let collections = [
            MODICollection(title: "오늘의 MODI", emoji: "🌈", type: .system),
            MODICollection(title: "카페", emoji: "☕️", type: .custom),
            MODICollection(title: "산책", emoji: "🚶", type: .custom)
        ]

        #expect(manager.customCollectionCount(in: collections) == 2)
        #expect(manager.canCreateCustomCollection(in: collections) == false)
    }
}
