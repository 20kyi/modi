import Foundation

// MARK: - ConceptType

enum ConceptType: String, Codable, CaseIterable, Identifiable {
    case system
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "기본 컨셉"
        case .custom: "나만의 컨셉"
        }
    }
}

// MARK: - Concept

/// 오늘의 기록 주제가 되는 컨셉.
/// Daily Mission은 새 미션을 만들지 않고, 기존 Concept 중 하나를 선택합니다.
struct Concept: Identifiable, Equatable, Codable, Hashable {
    let id: UUID
    let title: String
    let emoji: String
    let description: String
    let category: CollectionCategory
    let type: ConceptType

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - UI Helpers

extension Concept {
    /// DailyMissionCard 등 기존 UI와 연결하기 위한 테마 색상.
    var themeColorHex: String {
        PhotoCollection.collection(for: id)?.themeColorHex
            ?? Self.fallbackThemeColorHex(for: category)
    }

    private static func fallbackThemeColorHex(for category: CollectionCategory) -> String {
        switch category {
        case .color: "F8DDE8"
        case .nature: "E4ECF4"
        case .custom: "E8ECF0"
        }
    }
}

// MARK: - Factory

extension Concept {
    init(from collection: PhotoCollection, type: ConceptType) {
        self.init(
            id: collection.id,
            title: collection.title,
            emoji: collection.emoji,
            description: collection.description,
            category: collection.category,
            type: type
        )
    }
}

// MARK: - Mock Data

extension Concept {
    /// Color Collection (6) + Nature Collection (5)
    static let systemConcepts: [Concept] = PhotoCollection.builtIn.map {
        Concept(from: $0, type: .system)
    }

    static let colorConcepts: [Concept] = systemConcepts.filter { $0.category == .color }
    static let natureConcepts: [Concept] = systemConcepts.filter { $0.category == .nature }

    static let mock = systemConcepts[6] // Cloud Hunter

    static let mockCustom = Concept(
        id: UUID(uuidString: "C3000001-0000-0000-0000-000000000001")!,
        title: "카페 순간",
        emoji: "☕️",
        description: "오늘 마신 커피와 카페의 분위기를 남겨요",
        category: .custom,
        type: .custom
    )

    static func concept(for id: UUID, including custom: [Concept] = []) -> Concept? {
        (systemConcepts + custom).first { $0.id == id }
    }
}
