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

    init?(serverValue: String) {
        switch serverValue.uppercased() {
        case "SYSTEM": self = .system
        case "CUSTOM": self = .custom
        default: return nil
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
    let missionPrompt: String
    let themeColorHex: String

    init(
        id: UUID,
        title: String,
        emoji: String,
        description: String,
        category: CollectionCategory,
        type: ConceptType,
        missionPrompt: String = "",
        themeColorHex: String = "E8ECF0"
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.description = description
        self.category = category
        self.type = type
        self.missionPrompt = missionPrompt
        self.themeColorHex = themeColorHex
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, emoji, description, category, type, missionPrompt, themeColorHex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        emoji = try container.decode(String.self, forKey: .emoji)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(CollectionCategory.self, forKey: .category)
        type = try container.decode(ConceptType.self, forKey: .type)
        missionPrompt = try container.decodeIfPresent(String.self, forKey: .missionPrompt) ?? ""
        themeColorHex = try container.decodeIfPresent(String.self, forKey: .themeColorHex)
            ?? PhotoCollection.collection(for: id)?.themeColorHex
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
            type: type,
            missionPrompt: collection.missionPrompt,
            themeColorHex: collection.themeColorHex
        )
    }

    init?(server: ServerConceptResponse) {
        guard let id = UUID(uuidString: server.id),
              let type = ConceptType(serverValue: server.type),
              let category = CollectionCategory(serverValue: server.category)
        else { return nil }

        self.init(
            id: id,
            title: server.title,
            emoji: server.emoji,
            description: server.description,
            category: category,
            type: type,
            missionPrompt: server.missionPrompt,
            themeColorHex: server.themeColorHex
        )
    }
}

// MARK: - Lookup

extension Concept {
    static func concept(
        for id: UUID,
        system: [Concept] = SystemConceptCatalog.shared.concepts,
        including custom: [Concept] = []
    ) -> Concept? {
        (system + custom).first { $0.id == id }
    }
}

// MARK: - Bundled Fallback

extension Concept {
    /// 네트워크·캐시 모두 없을 때 사용하는 번들 기본값.
    static let bundledFallback: [Concept] = PhotoCollection.builtIn.map {
        Concept(from: $0, type: .system)
    }

    static let mock = bundledFallback[6] // Cloud Hunter

    static let mockCustom = Concept(
        id: UUID(uuidString: "C3000001-0000-0000-0000-000000000001")!,
        title: "카페 순간",
        emoji: "☕️",
        description: "오늘 마신 커피와 카페의 분위기를 남겨요",
        category: .custom,
        type: .custom
    )
}

// MARK: - Server Category Bridge

extension CollectionCategory {
    init?(serverValue: String) {
        switch serverValue.uppercased() {
        case "COLOR": self = .color
        case "NATURE": self = .nature
        case "CUSTOM": self = .custom
        default: return nil
        }
    }
}
