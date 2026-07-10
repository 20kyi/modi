import Foundation
import SwiftUI

// MARK: - DailyMission

/// 하루에 하나씩 배정되는 사진 미션.
struct DailyMission: Codable, Equatable, Identifiable {
    let id: UUID
    let title: String
    let emoji: String
    let description: String
    let category: CollectionCategory
    let themeColorHex: String
    let collectionID: UUID
    let date: Date
    var isCompleted: Bool

    var themeColor: Color { Color(hex: themeColorHex) }

    var dayKey: String {
        Self.dayKey(for: date)
    }

    init(
        id: UUID = UUID(),
        title: String,
        emoji: String,
        description: String,
        category: CollectionCategory,
        themeColorHex: String,
        collectionID: UUID,
        date: Date = .now,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.description = description
        self.category = category
        self.themeColorHex = themeColorHex
        self.collectionID = collectionID
        self.date = Calendar.current.startOfDay(for: date)
        self.isCompleted = isCompleted
    }

    init(from collection: PhotoCollection, date: Date = .now, isCompleted: Bool = false) {
        self.init(
            title: collection.title,
            emoji: collection.emoji,
            description: collection.description,
            category: collection.category,
            themeColorHex: collection.themeColorHex,
            collectionID: collection.id,
            date: date,
            isCompleted: isCompleted
        )
    }

    init(from concept: Concept, date: Date = .now, isCompleted: Bool = false) {
        self.init(
            title: concept.title,
            emoji: concept.emoji,
            description: concept.description,
            category: concept.category,
            themeColorHex: concept.themeColorHex,
            collectionID: concept.id,
            date: date,
            isCompleted: isCompleted
        )
    }

    func with(isCompleted: Bool) -> DailyMission {
        var copy = self
        copy.isCompleted = isCompleted
        return copy
    }

    static func dayKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, emoji, description, category, themeColorHex, collectionID, date
        case prompt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        collectionID = try container.decode(UUID.self, forKey: .collectionID)
        date = try container.decode(Date.self, forKey: .date)
        isCompleted = false

        if let title = try container.decodeIfPresent(String.self, forKey: .title) {
            self.title = title
            emoji = try container.decode(String.self, forKey: .emoji)
            description = try container.decode(String.self, forKey: .description)
            category = try container.decode(CollectionCategory.self, forKey: .category)
            themeColorHex = try container.decode(String.self, forKey: .themeColorHex)
        } else {
            let legacyPrompt = try container.decode(String.self, forKey: .prompt)
            if let collection = PhotoCollection.collection(for: collectionID) {
                title = collection.title
                emoji = collection.emoji
                description = legacyPrompt
                category = collection.category
                themeColorHex = collection.themeColorHex
            } else {
                title = "오늘의 미션"
                emoji = "📷"
                description = legacyPrompt
                category = .custom
                themeColorHex = "E8ECF0"
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encode(themeColorHex, forKey: .themeColorHex)
        try container.encode(collectionID, forKey: .collectionID)
        try container.encode(date, forKey: .date)
    }
}

// MARK: - Mock

extension DailyMission {
    static let mock = DailyMission(
        id: UUID(uuidString: "D1000001-0000-0000-0000-000000000001")!,
        title: "Cloud Hunter",
        emoji: "☁️",
        description: "오늘의 특별한 구름을 찾아보세요",
        category: .nature,
        themeColorHex: "E4ECF4",
        collectionID: PhotoCollection.builtIn[6].id,
        isCompleted: false
    )

    static let mockCompleted = DailyMission(
        id: UUID(uuidString: "D1000001-0000-0000-0000-000000000002")!,
        title: "Cloud Hunter",
        emoji: "☁️",
        description: "오늘의 특별한 구름을 찾아보세요",
        category: .nature,
        themeColorHex: "E4ECF4",
        collectionID: PhotoCollection.builtIn[6].id,
        isCompleted: true
    )
}

// MARK: - MissionEntry

/// 완료한 미션 기록. 해당 컬렉션에 사진이 쌓임.
struct MissionEntry: Codable, Equatable, Identifiable {
    let id: UUID
    let collectionID: UUID
    let missionDate: Date
    let completedAt: Date
    let prompt: String
    let imageFileName: String?

    init(
        id: UUID = UUID(),
        collectionID: UUID,
        missionDate: Date,
        prompt: String,
        imageFileName: String,
        completedAt: Date = .now
    ) {
        self.id = id
        self.collectionID = collectionID
        self.missionDate = Calendar.current.startOfDay(for: missionDate)
        self.completedAt = completedAt
        self.prompt = prompt
        self.imageFileName = imageFileName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        collectionID = try container.decode(UUID.self, forKey: .collectionID)
        missionDate = try container.decode(Date.self, forKey: .missionDate)
        completedAt = try container.decode(Date.self, forKey: .completedAt)
        prompt = try container.decode(String.self, forKey: .prompt)
        imageFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName)
    }
}

// MARK: - RecentDiscovery

struct RecentDiscovery: Identifiable, Equatable {
    let id: UUID
    let record: MODIRecord
    let emoji: String
    let title: String
    let subtitle: String
    let relativeDate: String
    let themeColorHex: String

    var themeColor: Color { Color(hex: themeColorHex) }

    static func == (lhs: RecentDiscovery, rhs: RecentDiscovery) -> Bool {
        lhs.id == rhs.id
    }
}

extension RecentDiscovery {
    static func mockList(from records: [MODIRecord]) -> [RecentDiscovery] {
        records.prefix(3).map { record in
            RecentDiscovery(
                id: record.id,
                record: record,
                emoji: record.conceptEmoji,
                title: record.conceptTitle,
                subtitle: record.collection?.title ?? "MODI 발견",
                relativeDate: "어제",
                themeColorHex: record.collection?.themeColorHex ?? "E8ECF0"
            )
        }
    }
}

// MARK: - TodaysMissionCollectionGallery

struct TodaysMissionCollectionGallery {
    let collectionID: UUID
    let title: String
    let emoji: String
    let themeColorHex: String
    let missionPrompt: String
    let records: [MODIRecord]

    var photoCount: Int { records.count }
    var themeColor: Color { Color(hex: themeColorHex) }
}

extension TodaysMissionCollectionGallery {
    static let mockBlue = TodaysMissionCollectionGallery(
        collectionID: PhotoCollection.builtIn[1].id,
        title: PhotoCollection.builtIn[1].title,
        emoji: PhotoCollection.builtIn[1].emoji,
        themeColorHex: PhotoCollection.builtIn[1].themeColorHex,
        missionPrompt: PhotoCollection.builtIn[1].missionPrompt,
        records: []
    )
}

// MARK: - CollectionPreviewItem (legacy preview)

struct CollectionPreviewItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let emoji: String
    let photoCount: Int
    let themeColorHex: String

    var themeColor: Color { Color(hex: themeColorHex) }
}

extension CollectionPreviewItem {
    static let mockList: [CollectionPreviewItem] = [
        CollectionPreviewItem(
            id: PhotoCollection.builtIn[6].id,
            title: "Cloud Hunter",
            emoji: "☁️",
            photoCount: 8,
            themeColorHex: "E4ECF4"
        ),
        CollectionPreviewItem(
            id: PhotoCollection.builtIn[0].id,
            title: "Pink Love",
            emoji: "🩷",
            photoCount: 12,
            themeColorHex: "F8DDE8"
        ),
        CollectionPreviewItem(
            id: PhotoCollection.builtIn[7].id,
            title: "Little Plant",
            emoji: "🪴",
            photoCount: 5,
            themeColorHex: "DCE8D4"
        )
    ]
}
