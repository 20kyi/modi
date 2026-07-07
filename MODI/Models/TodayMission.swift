import Foundation

// MARK: - TodayMission

/// 특정 날짜에 선택된 Concept을 나타내는 오늘의 미션.
struct TodayMission: Identifiable, Equatable, Codable {
    let id: UUID
    let conceptId: UUID
    let date: Date

    var dayKey: String {
        Self.dayKey(for: date)
    }

    init(
        id: UUID = UUID(),
        conceptId: UUID,
        date: Date = .now
    ) {
        self.id = id
        self.conceptId = conceptId
        self.date = Calendar.current.startOfDay(for: date)
    }

    static func dayKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}

// MARK: - Mock Data

extension TodayMission {
    static let mock = TodayMission(
        id: UUID(uuidString: "T1000001-0000-0000-0000-000000000001")!,
        conceptId: Concept.mock.id,
        date: .now
    )
}
