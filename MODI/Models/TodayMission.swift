import Foundation

// MARK: - TodayMission

/// 특정 사용자/날짜에 선택된 컬렉션을 나타내는 오늘의 미션.
struct TodayMission: Identifiable, Equatable, Codable {
    let id: UUID
    let userId: String
    let collectionId: UUID
    let initialCollectionId: UUID
    let date: Date
    var isCompleted: Bool
    let hasChangedCollection: Bool

    var dayKey: String {
        Self.dayKey(for: date)
    }

    /// 기존 Concept 기반 호출부와의 호환용 별칭입니다.
    var conceptId: UUID { collectionId }

    /// 기존 미션 변경 로직과의 호환용 별칭입니다.
    var initialConceptId: UUID { initialCollectionId }

    /// 기존 미션 변경 제한 마이그레이션과의 호환용 별칭입니다.
    var hasChangedConcept: Bool { hasChangedCollection }

    init(
        id: UUID = UUID(),
        userId: String,
        collectionId: UUID,
        initialCollectionId: UUID? = nil,
        date: Date = .now,
        isCompleted: Bool = false,
        hasChangedCollection: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.collectionId = collectionId
        self.initialCollectionId = initialCollectionId ?? collectionId
        self.date = Calendar.current.startOfDay(for: date)
        self.isCompleted = isCompleted
        self.hasChangedCollection = hasChangedCollection
    }

    enum CodingKeys: String, CodingKey {
        case id, userId, collectionId, initialCollectionId, date, isCompleted, hasChangedCollection
        case conceptId, initialConceptId, hasChangedConcept
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decodeIfPresent(String.self, forKey: .userId) ?? "guest"
        if let collectionId = try container.decodeIfPresent(UUID.self, forKey: .collectionId) {
            self.collectionId = collectionId
        } else {
            self.collectionId = try container.decode(UUID.self, forKey: .conceptId)
        }
        date = try container.decode(Date.self, forKey: .date)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        hasChangedCollection = try container.decodeIfPresent(Bool.self, forKey: .hasChangedCollection)
            ?? (try container.decodeIfPresent(Bool.self, forKey: .hasChangedConcept) ?? false)

        if let initialCollectionId = try container.decodeIfPresent(UUID.self, forKey: .initialCollectionId) {
            self.initialCollectionId = initialCollectionId
        } else {
            self.initialCollectionId = try container.decodeIfPresent(UUID.self, forKey: .initialConceptId) ?? self.collectionId
        }
    }

    func withCompletion(_ isCompleted: Bool) -> TodayMission {
        var copy = self
        copy.isCompleted = isCompleted
        return copy
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(collectionId, forKey: .collectionId)
        try container.encode(initialCollectionId, forKey: .initialCollectionId)
        try container.encode(date, forKey: .date)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(hasChangedCollection, forKey: .hasChangedCollection)
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
        userId: "mock-user",
        collectionId: Concept.mock.id,
        date: .now
    )
}
