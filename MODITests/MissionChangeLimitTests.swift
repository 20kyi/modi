import Foundation
import SwiftData
import Testing
import UIKit
@testable import MODI

@MainActor
struct MissionChangeLimitTests {

    private func makeMissionManagerWithConcepts(
        suiteName: String,
        conceptCount: Int = 4
    ) -> (MissionManager, RecordRepository, CollectionRepository, [Concept]) {
        let storage = UserDefaults(suiteName: suiteName)!
        storage.removePersistentDomain(forName: suiteName)

        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema = Schema([MODIRecord.self, MODICollection.self])
        let container = try! ModelContainer(for: schema, configurations: configuration)
        let collectionRepository = CollectionRepository(modelContext: container.mainContext)
        collectionRepository.bootstrap()
        let repository = RecordRepository(modelContext: container.mainContext)

        let concepts = (0..<conceptCount).map { index in
            collectionRepository.addCustomCollection(
                title: "Test \(index)",
                emoji: "⭐️",
                missionPrompt: "prompt \(index)",
                description: "desc \(index)",
                themeColorHex: "E8ECF0"
            ).concept
        }

        let manager = MissionManager(storage: storage)
        manager.configure(collectionRepository: collectionRepository)
        return (manager, repository, collectionRepository, concepts)
    }

    @Test func freeUserCanChangeMissionOnce() {
        let (manager, repository, _, concepts) = makeMissionManagerWithConcepts(
            suiteName: "mission-change-free-once"
        )

        manager.selectConcept(concepts[0], for: .now)

        #expect(manager.canChangeMission(repository: repository, hasPremium: false))
        #expect(manager.changeMission(to: concepts[1], repository: repository, hasPremium: false))
        #expect(manager.canChangeMission(repository: repository, hasPremium: false) == false)
    }

    @Test func premiumUserCanChangeMissionThreeTimes() {
        let (manager, repository, _, concepts) = makeMissionManagerWithConcepts(
            suiteName: "mission-change-premium-three"
        )

        manager.selectConcept(concepts[0], for: .now)

        #expect(manager.canChangeMission(repository: repository, hasPremium: true))
        #expect(manager.changeMission(to: concepts[1], repository: repository, hasPremium: true))

        #expect(manager.canChangeMission(repository: repository, hasPremium: true))
        #expect(manager.changeMission(to: concepts[2], repository: repository, hasPremium: true))

        #expect(manager.canChangeMission(repository: repository, hasPremium: true))
        #expect(manager.changeMission(to: concepts[3], repository: repository, hasPremium: true))

        #expect(manager.canChangeMission(repository: repository, hasPremium: true) == false)
    }

    @Test func missionChangeCountResetsOnNewDay() {
        let (manager, repository, _, concepts) = makeMissionManagerWithConcepts(
            suiteName: "mission-change-reset-day"
        )

        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: .now)!
        manager.selectConcept(concepts[0], for: yesterday)
        #expect(manager.changeMission(to: concepts[1], on: yesterday, repository: repository, hasPremium: false))
        #expect(manager.canChangeMission(on: yesterday, repository: repository, hasPremium: false) == false)

        manager.selectConcept(concepts[0], for: .now)
        #expect(manager.canChangeMission(repository: repository, hasPremium: false))
    }

    @Test func completedMissionCannotBeChanged() {
        let (manager, repository, collectionRepository, concepts) = makeMissionManagerWithConcepts(
            suiteName: "mission-change-completed"
        )
        manager.selectConcept(concepts[0], for: .now)

        let collection = collectionRepository.ensureCollection(for: concepts[0])
        _ = try? repository.saveRecord(
            image: UIImage(systemName: "photo")!,
            originalImage: UIImage(systemName: "photo")!,
            concept: concepts[0],
            collection: collection
        )

        #expect(manager.canChangeMission(repository: repository, hasPremium: true) == false)
    }

    @Test func remainingMissionChangeCountReflectsUsage() {
        let (manager, repository, _, concepts) = makeMissionManagerWithConcepts(
            suiteName: "mission-change-remaining-count"
        )

        manager.selectConcept(concepts[0], for: .now)

        #expect(manager.remainingMissionChangeCount(hasPremium: false) == 1)
        #expect(manager.changeMission(to: concepts[1], repository: repository, hasPremium: false))
        #expect(manager.remainingMissionChangeCount(hasPremium: false) == 0)

        #expect(manager.remainingMissionChangeCount(hasPremium: true) == 2)
        #expect(manager.changeMission(to: concepts[2], repository: repository, hasPremium: true))
        #expect(manager.remainingMissionChangeCount(hasPremium: true) == 1)
    }

    @Test func freeUserAtLimitDoesNotConsumeExtraChangeOnBlockedAttempt() {
        let (manager, repository, _, concepts) = makeMissionManagerWithConcepts(
            suiteName: "mission-change-blocked-attempt"
        )

        manager.selectConcept(concepts[0], for: .now)
        #expect(manager.changeMission(to: concepts[1], repository: repository, hasPremium: false))

        #expect(manager.canChangeMission(repository: repository, hasPremium: false) == false)
        #expect(manager.changeMission(to: concepts[2], repository: repository, hasPremium: false) == false)
        #expect(manager.rerollMission(repository: repository, hasPremium: false) == nil)

        #expect(manager.remainingMissionChangeCount(hasPremium: false) == 0)
        #expect(manager.remainingMissionChangeCount(hasPremium: true) == 2)
    }

    @Test func missionChangeLimitsAreConfigured() {
        #expect(PremiumManager.freeMissionChangeLimit == 1)
        #expect(PremiumManager.premiumMissionChangeLimit == 3)
    }

    @Test func premiumManagerCanChangeMissionUsesHasPremium() {
        let freeStorage = UserDefaults(suiteName: "mission-change-premium-manager-free")!
        freeStorage.removePersistentDomain(forName: "mission-change-premium-manager-free")
        let freeManager = PremiumManager(storage: freeStorage)
        freeManager.setDeveloperPremiumEnabled(false)
        #expect(freeManager.canChangeMission(currentCount: 0) == true)
        #expect(freeManager.canChangeMission(currentCount: 1) == false)

        let premiumStorage = UserDefaults(suiteName: "mission-change-premium-manager-premium")!
        premiumStorage.removePersistentDomain(forName: "mission-change-premium-manager-premium")
        let premiumManager = PremiumManager(storage: premiumStorage)
        premiumManager.setDeveloperPremiumEnabled(true)
        #expect(premiumManager.canChangeMission(currentCount: 2) == true)
        #expect(premiumManager.canChangeMission(currentCount: 3) == false)
    }

    @Test func missionSelectionUsesOnlyIncludedCollections() {
        let (manager, _, collectionRepository, concepts) = makeMissionManagerWithConcepts(
            suiteName: "mission-inclusion-only-enabled",
            conceptCount: 2
        )

        for collection in collectionRepository.systemCollections {
            collectionRepository.updateMissionInclusion(collection, isIncludedInMission: false)
        }

        let excluded = collectionRepository.ensureCollection(for: concepts[0])
        let included = collectionRepository.ensureCollection(for: concepts[1])
        collectionRepository.updateMissionInclusion(excluded, isIncludedInMission: false)
        collectionRepository.updateMissionInclusion(included, isIncludedInMission: true)

        let targetDate = Date(timeIntervalSince1970: 1_735_689_600)
        let mission = manager.mission(for: targetDate)
        #expect(mission.conceptId == included.id)
    }

    @Test func missionFallsBackSafelyWhenAllCollectionsAreExcluded() {
        let (manager, _, collectionRepository, _) = makeMissionManagerWithConcepts(
            suiteName: "mission-inclusion-all-disabled",
            conceptCount: 1
        )

        for collection in collectionRepository.collections {
            collectionRepository.updateMissionInclusion(collection, isIncludedInMission: false)
        }

        let targetDate = Date(timeIntervalSince1970: 1_735_776_000)
        let mission = manager.mission(for: targetDate)
        let fallbackConcept = manager.systemConcepts.first ?? Concept.mock
        #expect(mission.conceptId == fallbackConcept.id)
    }

    @Test func sameUserAndDateSelectSameMissionAcrossDevices() {
        let firstStorage = UserDefaults(suiteName: "mission-sync-device-a")!
        let secondStorage = UserDefaults(suiteName: "mission-sync-device-b")!
        firstStorage.removePersistentDomain(forName: "mission-sync-device-a")
        secondStorage.removePersistentDomain(forName: "mission-sync-device-b")
        firstStorage.set("same-user", forKey: "modi_auth_userId")
        secondStorage.set("same-user", forKey: "modi_auth_userId")

        let (_, _, firstCollectionRepository, _) = makeMissionManagerWithConcepts(
            suiteName: "mission-sync-device-a",
            conceptCount: 0
        )
        firstStorage.set("same-user", forKey: "modi_auth_userId")
        let firstManager = MissionManager(storage: firstStorage)
        firstManager.configure(collectionRepository: firstCollectionRepository)

        let (_, _, secondCollectionRepository, _) = makeMissionManagerWithConcepts(
            suiteName: "mission-sync-device-b",
            conceptCount: 0
        )
        secondStorage.set("same-user", forKey: "modi_auth_userId")
        let secondManager = MissionManager(storage: secondStorage)
        secondManager.configure(collectionRepository: secondCollectionRepository)

        let date = Date(timeIntervalSince1970: 1_784_044_800)
        let firstMission = firstManager.mission(for: date)
        let secondMission = secondManager.mission(for: date)

        #expect(firstMission.userId == "same-user")
        #expect(secondMission.userId == "same-user")
        #expect(firstMission.collectionId == secondMission.collectionId)
    }

    @Test func missionCompletionSyncsFromSyncedRecord() {
        let (manager, repository, collectionRepository, _) = makeMissionManagerWithConcepts(
            suiteName: "mission-completion-sync",
            conceptCount: 0
        )
        let date = Date(timeIntervalSince1970: 1_784_044_800)
        let mission = manager.mission(for: date)
        guard let concept = manager.concept(for: mission.collectionId) else {
            Issue.record("Missing mission concept")
            return
        }

        let collection = collectionRepository.ensureCollection(for: concept)
        _ = try? repository.saveRecord(
            image: UIImage(systemName: "photo")!,
            originalImage: UIImage(systemName: "photo")!,
            concept: concept,
            collection: collection,
            recordDate: date
        )
        manager.syncCompletionStatus(on: date, repository: repository)

        #expect(manager.mission(for: date).isCompleted)
        #expect(manager.isMissionCompleted(on: date, repository: repository))
    }

    @Test func missionIsStoredSeparatelyByDate() {
        let (manager, _, _, _) = makeMissionManagerWithConcepts(
            suiteName: "mission-date-separate",
            conceptCount: 0
        )
        let calendar = Calendar.current
        let firstDate = Date(timeIntervalSince1970: 1_784_044_800)
        let secondDate = calendar.date(byAdding: .day, value: 1, to: firstDate)!

        let firstMission = manager.mission(for: firstDate)
        let secondMission = manager.mission(for: secondDate)

        #expect(firstMission.dayKey != secondMission.dayKey)
        #expect(firstMission.date != secondMission.date)
    }
}
