import SwiftUI

// MARK: - CollectionCategory

enum CollectionCategory: String, CaseIterable, Identifiable, Codable {
    case color = "color"
    case nature = "nature"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .color: "Color Collection"
        case .nature: "Nature Collection"
        case .custom: "Custom Collection"
        }
    }
}

// MARK: - PhotoCollection

struct PhotoCollection: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    let title: String
    let emoji: String
    let category: CollectionCategory
    let description: String
    let missionPrompt: String
    let themeColorHex: String
    let isBuiltIn: Bool
    let sourceTemplateID: String?
    var isIncludedInMission: Bool = true

    var themeColor: Color { Color(hex: themeColorHex) }

    static func == (lhs: PhotoCollection, rhs: PhotoCollection) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension PhotoCollection {
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case emoji
        case category
        case description
        case missionPrompt
        case themeColorHex
        case isBuiltIn
        case sourceTemplateID
        case isIncludedInMission
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        emoji = try container.decode(String.self, forKey: .emoji)
        category = try container.decode(CollectionCategory.self, forKey: .category)
        description = try container.decode(String.self, forKey: .description)
        missionPrompt = try container.decode(String.self, forKey: .missionPrompt)
        themeColorHex = try container.decode(String.self, forKey: .themeColorHex)
        isBuiltIn = try container.decode(Bool.self, forKey: .isBuiltIn)
        sourceTemplateID = try container.decodeIfPresent(String.self, forKey: .sourceTemplateID)
        isIncludedInMission = try container.decodeIfPresent(Bool.self, forKey: .isIncludedInMission) ?? true
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(category, forKey: .category)
        try container.encode(description, forKey: .description)
        try container.encode(missionPrompt, forKey: .missionPrompt)
        try container.encode(themeColorHex, forKey: .themeColorHex)
        try container.encode(isBuiltIn, forKey: .isBuiltIn)
        try container.encodeIfPresent(sourceTemplateID, forKey: .sourceTemplateID)
        try container.encode(isIncludedInMission, forKey: .isIncludedInMission)
    }
}

// MARK: - Built-in Collections

extension PhotoCollection {

    static let builtIn: [PhotoCollection] = [
        // Color
        PhotoCollection(
            id: UUID(uuidString: "A1000001-0000-0000-0000-000000000001")!,
            title: "Pink Love",
            emoji: "🩷",
            category: .color,
            description: "사랑스러운 분홍빛 순간을 모아요",
            missionPrompt: "분홍색을 찍으세요",
            themeColorHex: "F8DDE8",
            isBuiltIn: true,
            sourceTemplateID: nil
        ),
        PhotoCollection(
            id: UUID(uuidString: "A1000001-0000-0000-0000-000000000002")!,
            title: "Blue Mood",
            emoji: "💙",
            category: .color,
            description: "차분한 파란 순간들을 모아보세요",
            missionPrompt: "파란색을 찍으세요",
            themeColorHex: "D4E4F7",
            isBuiltIn: true,
            sourceTemplateID: nil
        ),
        PhotoCollection(
            id: UUID(uuidString: "A1000001-0000-0000-0000-000000000003")!,
            title: "Purple Dream",
            emoji: "💜",
            category: .color,
            description: "몽환적인 보라빛 하루를 기록해요",
            missionPrompt: "보라색을 찍으세요",
            themeColorHex: "E8DDF5",
            isBuiltIn: true,
            sourceTemplateID: nil
        ),
        PhotoCollection(
            id: UUID(uuidString: "A1000001-0000-0000-0000-000000000004")!,
            title: "Yellow Day",
            emoji: "💛",
            category: .color,
            description: "밝고 따뜻한 노란 하루를 담아요",
            missionPrompt: "노란색을 찍으세요",
            themeColorHex: "F9F0C8",
            isBuiltIn: true,
            sourceTemplateID: nil
        ),
        PhotoCollection(
            id: UUID(uuidString: "A1000001-0000-0000-0000-000000000005")!,
            title: "Green Life",
            emoji: "💚",
            category: .color,
            description: "싱그러운 초록의 일상을 수집해요",
            missionPrompt: "초록색을 찍으세요",
            themeColorHex: "D8EDDF",
            isBuiltIn: true,
            sourceTemplateID: nil
        ),
        PhotoCollection(
            id: UUID(uuidString: "A1000001-0000-0000-0000-000000000006")!,
            title: "White Moment",
            emoji: "🤍",
            category: .color,
            description: "고요하고 깨끗한 순간을 남겨요",
            missionPrompt: "하얀색을 찍으세요",
            themeColorHex: "F2F2F4",
            isBuiltIn: true,
            sourceTemplateID: nil
        ),

        // Nature
        PhotoCollection(
            id: UUID(uuidString: "B2000001-0000-0000-0000-000000000001")!,
            title: "Cloud Hunter",
            emoji: "☁️",
            category: .nature,
            description: "하늘 위 구름을 찾아 떠나요",
            missionPrompt: "하늘을 찍으세요",
            themeColorHex: "E4ECF4",
            isBuiltIn: true,
            sourceTemplateID: nil
        ),
        PhotoCollection(
            id: UUID(uuidString: "B2000001-0000-0000-0000-000000000002")!,
            title: "Little Plant",
            emoji: "🪴",
            category: .nature,
            description: "작은 식물과 함께한 순간들",
            missionPrompt: "식물을 찍으세요",
            themeColorHex: "DCE8D4",
            isBuiltIn: true,
            sourceTemplateID: nil
        ),
        PhotoCollection(
            id: UUID(uuidString: "B2000001-0000-0000-0000-000000000003")!,
            title: "Flower Diary",
            emoji: "🌸",
            category: .nature,
            description: "피어난 꽃의 아름다움을 기록해요",
            missionPrompt: "꽃을 찍으세요",
            themeColorHex: "F5E0E8",
            isBuiltIn: true,
            sourceTemplateID: nil
        ),
        PhotoCollection(
            id: UUID(uuidString: "B2000001-0000-0000-0000-000000000004")!,
            title: "Animal Friend",
            emoji: "🐾",
            category: .nature,
            description: "귀여운 동물 친구들을 만나요",
            missionPrompt: "동물을 찍으세요",
            themeColorHex: "EDE4D8",
            isBuiltIn: true,
            sourceTemplateID: nil
        ),
        PhotoCollection(
            id: UUID(uuidString: "B2000001-0000-0000-0000-000000000005")!,
            title: "Sky Time",
            emoji: "🌙",
            category: .nature,
            description: "밤하늘과 저녁 노을의 시간",
            missionPrompt: "밤하늘을 찍으세요",
            themeColorHex: "D8DCE8",
            isBuiltIn: true,
            sourceTemplateID: nil
        )
    ]

    static let presetColorHexes = [
        "F8DDE8", "D4E4F7", "E8DDF5", "F9F0C8", "D8EDDF", "F2F2F4",
        "E4ECF4", "DCE8D4", "F5E0E8", "EDE4D8", "D8DCE8", "F0E8E0"
    ]

    static func collection(for id: UUID, including custom: [PhotoCollection] = []) -> PhotoCollection? {
        (builtIn + custom).first { $0.id == id }
    }

    static func collections(in category: CollectionCategory, custom: [PhotoCollection] = []) -> [PhotoCollection] {
        switch category {
        case .custom:
            custom
        default:
            builtIn.filter { $0.category == category }
        }
    }
}

// MARK: - Heart Emoji Presets

extension PhotoCollection {

    /// 하트 이모지 선택 시 커스텀 컬렉션 폼 자동 채움용. Color Collection 문구를 우선 사용합니다.
    static func heartCollectionPreset(for emoji: String) -> PhotoCollection? {
        if let colorCollection = builtIn.first(where: { $0.category == .color && $0.emoji == emoji }) {
            return colorCollection
        }
        return additionalHeartPresets[emoji]
    }

    private static let additionalHeartPresets: [String: PhotoCollection] = [
        "❤️": PhotoCollection(
            id: UUID(uuidString: "C4000001-0000-0000-0000-000000000001")!,
            title: "Red Love",
            emoji: "❤️",
            category: .color,
            description: "따뜻한 빨간 순간을 모아요",
            missionPrompt: "빨간색을 찍으세요",
            themeColorHex: "F5D0D0",
            isBuiltIn: false,
            sourceTemplateID: nil
        ),
        "🧡": PhotoCollection(
            id: UUID(uuidString: "C4000001-0000-0000-0000-000000000002")!,
            title: "Orange Day",
            emoji: "🧡",
            category: .color,
            description: "밝고 따뜻한 주황 하루를 담아요",
            missionPrompt: "주황색을 찍으세요",
            themeColorHex: "F9E0C8",
            isBuiltIn: false,
            sourceTemplateID: nil
        ),
        "🖤": PhotoCollection(
            id: UUID(uuidString: "C4000001-0000-0000-0000-000000000003")!,
            title: "Black Mood",
            emoji: "🖤",
            category: .color,
            description: "깊고 차분한 검은 순간을 남겨요",
            missionPrompt: "검은색을 찍으세요",
            themeColorHex: "D8D8DC",
            isBuiltIn: false,
            sourceTemplateID: nil
        ),
        "🤎": PhotoCollection(
            id: UUID(uuidString: "C4000001-0000-0000-0000-000000000004")!,
            title: "Brown Life",
            emoji: "🤎",
            category: .color,
            description: "포근한 갈색의 일상을 수집해요",
            missionPrompt: "갈색을 찍으세요",
            themeColorHex: "E8DDD4",
            isBuiltIn: false,
            sourceTemplateID: nil
        ),
        "🩵": PhotoCollection(
            id: UUID(uuidString: "C4000001-0000-0000-0000-000000000005")!,
            title: "Sky Mood",
            emoji: "🩵",
            category: .color,
            description: "맑고 산뜻한 하늘빛 순간을 모아보세요",
            missionPrompt: "하늘색을 찍으세요",
            themeColorHex: "D0E8F5",
            isBuiltIn: false,
            sourceTemplateID: nil
        ),
        "🩶": PhotoCollection(
            id: UUID(uuidString: "C4000001-0000-0000-0000-000000000006")!,
            title: "Grey Moment",
            emoji: "🩶",
            category: .color,
            description: "고요한 회색의 하루를 기록해요",
            missionPrompt: "회색을 찍으세요",
            themeColorHex: "E8E8EC",
            isBuiltIn: false,
            sourceTemplateID: nil
        )
    ]
}
