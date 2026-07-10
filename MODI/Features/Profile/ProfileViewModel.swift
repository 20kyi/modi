import SwiftUI

// MARK: - Settings Item

enum ProfileSettingsDestination {
    case notifications
    case premium
    case appSettings
}

struct ProfileSettingsItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let isPremium: Bool
    let destination: ProfileSettingsDestination
}

// MARK: - ViewModel

@Observable
final class ProfileViewModel {

    private(set) var stats: DiscoveryStats = .empty
    private(set) var recordedDayEmojis: [String: String] = [:]
    private(set) var collectionSummaries: [ProfileCollectionSummary] = []
    private(set) var earnedTitles: [ProfileHighestTitle] = []

    let settingsItems: [ProfileSettingsItem] = [
        ProfileSettingsItem(title: "알림 설정", icon: "bell.fill", isPremium: false, destination: .notifications),
        ProfileSettingsItem(title: "Premium", icon: "crown.fill", isPremium: true, destination: .premium),
        ProfileSettingsItem(title: "앱 설정", icon: "gearshape.fill", isPremium: false, destination: .appSettings)
    ]

    func refresh(
        streakManager: StreakManager,
        recordRepository: RecordRepository,
        collectionRepository: CollectionRepository
    ) {
        stats = streakManager.stats
        recordedDayEmojis = Self.makeRecordedDayEmojis(from: recordRepository.fetchAllRecords())
        collectionSummaries = Self.makeCollectionSummaries(from: collectionRepository)
        earnedTitles = Self.makeEarnedTitles(
            from: collectionRepository,
            recordRepository: recordRepository
        )
    }

    // MARK: - Builders

    private static func makeRecordedDayEmojis(from records: [MODIRecord]) -> [String: String] {
        var dayEmojis: [String: String] = [:]

        for record in records.sorted(by: { $0.discoveryDate > $1.discoveryDate }) {
            let dayKey = DailyMission.dayKey(for: record.discoveryDate)
            guard dayEmojis[dayKey] == nil else { continue }
            dayEmojis[dayKey] = record.collection?.emoji ?? record.conceptEmoji
        }

        return dayEmojis
    }

    private static func makeCollectionSummaries(
        from collectionRepository: CollectionRepository
    ) -> [ProfileCollectionSummary] {
        collectionRepository.collections
            .filter { $0.photoCount > 0 }
            .sorted { ($0.latestRecordDate ?? .distantPast) > ($1.latestRecordDate ?? .distantPast) }
            .prefix(5)
            .map { collection in
                ProfileCollectionSummary(
                    id: collection.id,
                    title: collection.title,
                    emoji: collection.emoji,
                    momentCount: collection.photoCount
                )
            }
    }

    private static func makeEarnedTitles(
        from collectionRepository: CollectionRepository,
        recordRepository: RecordRepository
    ) -> [ProfileHighestTitle] {
        let titles: [ProfileHighestTitle] = collectionRepository.collections.compactMap { collection in
            let records = recordRepository.fetchRecords(for: collection)
            guard records.count > 0,
                  let title = collection.currentTitle
            else { return nil }

            let sortedRecords = records.sorted { $0.discoveryDate < $1.discoveryDate }
            let acquiredIndex = min(title.milestone, sortedRecords.count) - 1
            guard acquiredIndex >= 0, acquiredIndex < sortedRecords.count else { return nil }

            let acquiringRecord = sortedRecords[acquiredIndex]

            return ProfileHighestTitle(
                id: collection.id,
                title: title,
                collectionTitle: collection.title,
                emoji: collection.emoji,
                themeColorHex: collection.themeColorHex,
                acquiredDate: acquiringRecord.discoveryDate
            )
        }

        return titles.sorted { lhs, rhs in
            if lhs.title.milestone != rhs.title.milestone {
                return lhs.title.milestone > rhs.title.milestone
            }
            return lhs.acquiredDate > rhs.acquiredDate
        }
    }
}
