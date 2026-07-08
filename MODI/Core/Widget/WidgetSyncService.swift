import Observation
import UIKit
import WidgetKit

@Observable
@MainActor
final class DeepLinkCoordinator {
    var pendingDestination: MODIDeepLinkDestination?

    func handle(_ url: URL) {
        pendingDestination = MODIDeepLink.destination(from: url)
    }

    func consume(_ destination: MODIDeepLinkDestination) {
        guard pendingDestination == destination else { return }
        pendingDestination = nil
    }
}

enum WidgetSyncService {
    @MainActor
    static func sync(
        missionManager: MissionManager,
        recordRepository: RecordRepository,
        streakManager: StreakManager
    ) {
        let todayMission = missionManager.todaysMission
        guard let concept = missionManager.concept(for: todayMission.conceptId) else { return }

        let record = recordRepository.record(on: .now, conceptId: concept.id)
        let hasPhoto: Bool

        if let record {
            hasPhoto = WidgetDataStore.saveTodayPhoto(record.imageData)
        } else {
            WidgetDataStore.removeTodayPhoto()
            hasPhoto = false
        }

        let snapshot = WidgetDailySnapshot(
            dayKey: WidgetDayKey.today,
            conceptTitle: concept.title,
            conceptEmoji: concept.emoji,
            missionMessage: WidgetMissionText.message(for: concept.title),
            themeColorHex: concept.themeColorHex,
            streakDays: streakManager.stats.streakDays,
            hasPhoto: hasPhoto,
            updatedAt: .now
        )

        WidgetDataStore.save(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: AppGroupConstants.widgetKind)
    }
}
