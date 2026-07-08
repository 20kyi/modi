import Foundation

// MARK: - TodayMission

/// 특정 날짜에 선택된 Concept을 나타내는 오늘의 미션.
struct TodayMission: Identifiable, Equatable, Codable {
    let id: UUID
    let conceptId: UUID
    let initialConceptId: UUID
    let date: Date
    let hasChangedConcept: Bool

    var dayKey: String {
        Self.dayKey(for: date)
    }

    init(
        id: UUID = UUID(),
        conceptId: UUID,
        initialConceptId: UUID? = nil,
        date: Date = .now,
        hasChangedConcept: Bool = false
    ) {
        self.id = id
        self.conceptId = conceptId
        self.initialConceptId = initialConceptId ?? conceptId
        self.date = Calendar.current.startOfDay(for: date)
        self.hasChangedConcept = hasChangedConcept
    }

    enum CodingKeys: String, CodingKey {
        case id, conceptId, initialConceptId, date, hasChangedConcept
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        conceptId = try container.decode(UUID.self, forKey: .conceptId)
        date = try container.decode(Date.self, forKey: .date)
        hasChangedConcept = try container.decodeIfPresent(Bool.self, forKey: .hasChangedConcept) ?? false
        initialConceptId = try container.decodeIfPresent(UUID.self, forKey: .initialConceptId) ?? conceptId
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
