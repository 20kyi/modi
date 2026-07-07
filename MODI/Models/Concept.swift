import SwiftUI

// MARK: - ConceptCategory

enum ConceptCategory: String, CaseIterable, Identifiable {
    case colorCollection = "Color Collection"
    case natureCollection = "Nature Collection"

    var id: String { rawValue }

    var displayName: String { rawValue }
}

// MARK: - Concept

struct Concept: Identifiable, Equatable, Hashable {
    let id: UUID
    let title: String
    let emoji: String
    let category: ConceptCategory
    let description: String
    let themeColor: Color

    static func == (lhs: Concept, rhs: Concept) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Mock Data

extension Concept {

    static let mockConcepts: [Concept] = [
        // Color Collection
        Concept(
            id: UUID(uuidString: "A1000001-0000-0000-0000-000000000001")!,
            title: "Blue Mood",
            emoji: "🔵",
            category: .colorCollection,
            description: "차분한 파란 순간들을 모아보세요",
            themeColor: Color(hex: "D4E4F7")
        ),
        Concept(
            id: UUID(uuidString: "A1000001-0000-0000-0000-000000000002")!,
            title: "Purple Dream",
            emoji: "🟣",
            category: .colorCollection,
            description: "몽환적인 보라빛 하루를 기록해요",
            themeColor: Color(hex: "E8DDF5")
        ),
        Concept(
            id: UUID(uuidString: "A1000001-0000-0000-0000-000000000003")!,
            title: "Yellow Day",
            emoji: "🟡",
            category: .colorCollection,
            description: "밝고 따뜻한 노란 하루를 담아요",
            themeColor: Color(hex: "F9F0C8")
        ),
        Concept(
            id: UUID(uuidString: "A1000001-0000-0000-0000-000000000004")!,
            title: "Green Life",
            emoji: "🟢",
            category: .colorCollection,
            description: "싱그러운 초록의 일상을 수집해요",
            themeColor: Color(hex: "D8EDDF")
        ),
        Concept(
            id: UUID(uuidString: "A1000001-0000-0000-0000-000000000005")!,
            title: "White Moment",
            emoji: "⚪",
            category: .colorCollection,
            description: "고요하고 깨끗한 순간을 남겨요",
            themeColor: Color(hex: "F2F2F4")
        ),

        // Nature Collection
        Concept(
            id: UUID(uuidString: "B2000001-0000-0000-0000-000000000001")!,
            title: "Cloud Hunter",
            emoji: "☁️",
            category: .natureCollection,
            description: "하늘 위 구름을 찾아 떠나요",
            themeColor: Color(hex: "E4ECF4")
        ),
        Concept(
            id: UUID(uuidString: "B2000001-0000-0000-0000-000000000002")!,
            title: "Little Plant",
            emoji: "🪴",
            category: .natureCollection,
            description: "작은 식물과 함께한 순간들",
            themeColor: Color(hex: "DCE8D4")
        ),
        Concept(
            id: UUID(uuidString: "B2000001-0000-0000-0000-000000000003")!,
            title: "Flower Diary",
            emoji: "🌸",
            category: .natureCollection,
            description: "피어난 꽃의 아름다움을 기록해요",
            themeColor: Color(hex: "F5E0E8")
        ),
        Concept(
            id: UUID(uuidString: "B2000001-0000-0000-0000-000000000004")!,
            title: "Animal Friend",
            emoji: "🐾",
            category: .natureCollection,
            description: "귀여운 동물 친구들을 만나요",
            themeColor: Color(hex: "EDE4D8")
        ),
        Concept(
            id: UUID(uuidString: "B2000001-0000-0000-0000-000000000005")!,
            title: "Sky Time",
            emoji: "🌙",
            category: .natureCollection,
            description: "밤하늘과 저녁 노을의 시간",
            themeColor: Color(hex: "D8DCE8")
        )
    ]

    static func concepts(in category: ConceptCategory) -> [Concept] {
        mockConcepts.filter { $0.category == category }
    }
}
