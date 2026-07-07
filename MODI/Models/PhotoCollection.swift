import SwiftUI

// MARK: - CollectionCategory

enum CollectionCategory: String, CaseIterable, Identifiable, Codable {
    case color = "color"
    case nature = "nature"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .color: "컬러 컬렉션"
        case .nature: "네이처 컬렉션"
        case .custom: "나만의 컬렉션"
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

    var themeColor: Color { Color(hex: themeColorHex) }

    static func == (lhs: PhotoCollection, rhs: PhotoCollection) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
