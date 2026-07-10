import SwiftUI

// MARK: - ViewModel

@Observable
final class HomeViewModel {

    private(set) var recentDiscoveries: [RecentDiscovery] = []
    private(set) var todaysMissionGallery: TodaysMissionCollectionGallery?
    private(set) var monthlyConcept = MonthlyConcept.empty

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
        let records = recordRepository.fetchAllRecords()
        recentDiscoveries = Self.makeRecentDiscoveries(from: records)
        todaysMissionGallery = Self.makeTodaysMissionGallery(
            missionManager: missionManager,
            recordRepository: recordRepository,
            collectionRepository: collectionRepository
        )
        monthlyConcept = Self.makeMonthlyConcept(from: records)
    }

    // MARK: - Builders

    private static func makeMonthlyConcept(from records: [MODIRecord]) -> MonthlyConcept {
        let calendar = Calendar.current
        let monthRecords = records.filter {
            calendar.isDate($0.discoveryDate, equalTo: .now, toGranularity: .month)
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

    private static func makeRecentDiscoveries(from records: [MODIRecord]) -> [RecentDiscovery] {
        records
            .sorted { $0.discoveryDate > $1.discoveryDate }
            .prefix(3)
            .map { record in
                RecentDiscovery(
                    id: record.id,
                    record: record,
                    emoji: record.collection?.emoji ?? record.conceptEmoji,
                    title: record.conceptTitle,
                    subtitle: discoverySubtitle(for: record),
                    relativeDate: relativeDiscoveryDate(from: record.discoveryDate),
                    themeColorHex: themeColorHex(for: record)
                )
            }
    }

    private static func makeTodaysMissionGallery(
        missionManager: MissionManager,
        recordRepository: RecordRepository,
        collectionRepository: CollectionRepository
    ) -> TodaysMissionCollectionGallery? {
        let todaysRecords = recordRepository.fetchRecords(on: .now)
            .sorted { $0.createdAt > $1.createdAt }

        let conceptId = todaysRecords.first?.conceptId ?? missionManager.mission(for: .now).conceptId
        guard let concept = missionManager.concept(for: conceptId) else { return nil }

        let collection = collectionRepository.collection(for: conceptId)
        let photoCollection = PhotoCollection.collection(for: conceptId)
        let records = recordRepository.fetchRecords(conceptId: conceptId)
            .sorted { $0.discoveryDate > $1.discoveryDate }

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
