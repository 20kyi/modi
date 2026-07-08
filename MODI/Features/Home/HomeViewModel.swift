import SwiftUI

// MARK: - ViewModel

@Observable
final class HomeViewModel {

    let userName = "영임"

    private(set) var recentDiscoveries: [RecentDiscovery] = []
    private(set) var todaysMissionGallery: TodaysMissionCollectionGallery?

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "좋은 아침이에요"
        case 12..<18: return "좋은 오후예요"
        case 18..<22: return "좋은 저녁이에요"
        default: return "편안한 밤 되세요"
        }
    }

    func missionStatusMessage(isCompleted: Bool) -> String {
        isCompleted ? "오늘의 미션 완료 ✨" : "오늘의 발견을 시작해보세요"
    }

    func refresh(
        missionManager: MissionManager,
        recordRepository: RecordRepository,
        collectionRepository: CollectionRepository
    ) {
        recentDiscoveries = Self.makeRecentDiscoveries(from: recordRepository.fetchAllRecords())
        todaysMissionGallery = Self.makeTodaysMissionGallery(
            missionManager: missionManager,
            recordRepository: recordRepository,
            collectionRepository: collectionRepository
        )
    }

    // MARK: - Builders

    private static func makeRecentDiscoveries(from records: [MODIRecord]) -> [RecentDiscovery] {
        records
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(3)
            .map { record in
                RecentDiscovery(
                    id: record.id,
                    emoji: record.collection?.emoji ?? record.conceptEmoji,
                    title: record.conceptTitle,
                    subtitle: discoverySubtitle(for: record),
                    relativeDate: relativeDiscoveryDate(from: record.createdAt),
                    themeColorHex: themeColorHex(for: record)
                )
            }
    }

    private static func makeTodaysMissionGallery(
        missionManager: MissionManager,
        recordRepository: RecordRepository,
        collectionRepository: CollectionRepository
    ) -> TodaysMissionCollectionGallery? {
        let conceptId = missionManager.mission(for: .now).conceptId
        guard let concept = missionManager.concept(for: conceptId) else { return nil }

        let collection = collectionRepository.collection(for: conceptId)
        let photoCollection = PhotoCollection.collection(for: conceptId)
        let records = recordRepository.fetchRecords(conceptId: conceptId)
            .sorted { $0.createdAt > $1.createdAt }

        return TodaysMissionCollectionGallery(
            collectionID: conceptId,
            title: concept.title,
            emoji: concept.emoji,
            themeColorHex: collection?.themeColorHex ?? photoCollection?.themeColorHex ?? concept.themeColorHex,
            missionPrompt: collection?.missionPrompt ?? photoCollection?.missionPrompt ?? concept.description,
            records: records
        )
    }

    private static func discoverySubtitle(for record: MODIRecord) -> String {
        let collectionTitle = record.collection?.title
            ?? PhotoCollection.collection(for: record.conceptId)?.title

        if let collectionTitle, collectionTitle != record.conceptTitle {
            return collectionTitle
        }

        return record.collection?.collectionCategory.displayName
            ?? PhotoCollection.collection(for: record.conceptId)?.category.displayName
            ?? "MODI 발견"
    }

    private static func themeColorHex(for record: MODIRecord) -> String {
        record.collection?.themeColorHex
            ?? PhotoCollection.collection(for: record.conceptId)?.themeColorHex
            ?? "E8ECF0"
    }

    private static func relativeDiscoveryDate(from date: Date, relativeTo now: Date = .now) -> String {
        let calendar = Calendar.current
        let dayDiff = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: now)
        ).day ?? 0

        switch dayDiff {
        case 0: return "오늘"
        case 1: return "어제"
        default: return "\(dayDiff)일 전"
        }
    }
}
