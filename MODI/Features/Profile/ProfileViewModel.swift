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

    let nickname = "영임"
    let tagline = "MODI Explorer"

    private(set) var stats: DiscoveryStats = .empty
    private(set) var recordedDayKeys: Set<String> = []
    private(set) var monthlyConcept = MonthlyConcept.empty
    private(set) var collectionSummaries: [ProfileCollectionSummary] = []

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
        recordedDayKeys = streakManager.recordedDayKeys
        monthlyConcept = Self.makeMonthlyConcept(from: recordRepository.fetchAllRecords())
        collectionSummaries = Self.makeCollectionSummaries(from: collectionRepository)
    }

    // MARK: - Builders

    private static func makeMonthlyConcept(from records: [MODIRecord]) -> MonthlyConcept {
        let calendar = Calendar.current
        let monthRecords = records.filter {
            calendar.isDate($0.createdAt, equalTo: .now, toGranularity: .month)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월의 MODI"

        let topRecord = Dictionary(grouping: monthRecords, by: \.conceptId)
            .max(by: { $0.value.count < $1.value.count })?
            .value
            .first

        return MonthlyConcept(
            id: topRecord?.conceptId ?? UUID(),
            monthLabel: formatter.string(from: .now),
            title: topRecord?.conceptTitle ?? "이번 달 첫 발견을 기다려요",
            emoji: topRecord?.conceptEmoji ?? "✨",
            themeColorHex: topRecord.map { _ in "E8ECF0" } ?? "F0F2F5",
            currentRecordCount: monthRecords.count
        )
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
}

// MARK: - MonthlyConcept Empty

extension MonthlyConcept {
    static let empty = MonthlyConcept(
        id: UUID(),
        monthLabel: "이번 달 MODI",
        title: "이번 달 첫 발견을 기다려요",
        emoji: "✨",
        themeColorHex: "F0F2F5",
        currentRecordCount: 0
    )
}
