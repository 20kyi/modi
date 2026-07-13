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
}
