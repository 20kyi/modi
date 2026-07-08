import Foundation
import SwiftData
import SwiftUI

// MARK: - CollectionType

enum CollectionType: String, Codable, CaseIterable {
    case system
    case custom

    var displayName: String {
        switch self {
        case .system: "자동 컬렉션"
        case .custom: "Custom Collection"
        }
    }
}

// MARK: - MODICollection

/// SwiftData에 저장되는 컬렉션. 시스템 Concept과 사용자 Custom Concept을 모두 표현합니다.
@Model
final class MODICollection {

    var id: UUID
    var title: String
    var emoji: String
    /// `CollectionType` raw value
    var type: String
    var createdAt: Date
    var collectionDescription: String
    var missionPrompt: String
    var themeColorHex: String
    /// `CollectionCategory` raw value
    var category: String
    var sourceTemplateID: String?
    /// 컬렉션 완성 목표 발견 수.
    var targetCount: Int = 20

    @Relationship(deleteRule: .cascade, inverse: \MODIRecord.collection)
    var records: [MODIRecord]?

    init(
        id: UUID = UUID(),
        title: String,
        emoji: String,
        type: CollectionType,
        createdAt: Date = .now,
        collectionDescription: String = "",
        missionPrompt: String = "",
        themeColorHex: String = "E8ECF0",
        category: CollectionCategory = .custom,
        sourceTemplateID: String? = nil,
        targetCount: Int = 20
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.type = type.rawValue
        self.createdAt = createdAt
        self.collectionDescription = collectionDescription
        self.missionPrompt = missionPrompt
        self.themeColorHex = themeColorHex
        self.category = category.rawValue
        self.sourceTemplateID = sourceTemplateID
        self.targetCount = targetCount
    }
}

// MARK: - Computed Properties

extension MODICollection {
    var collectionType: CollectionType {
        CollectionType(rawValue: type) ?? .system
    }

    var collectionCategory: CollectionCategory {
        CollectionCategory(rawValue: category) ?? .custom
    }

    var themeColor: Color {
        Color(hex: themeColorHex)
    }

    var photoCount: Int {
        records?.count ?? 0
    }

    var currentCount: Int {
        photoCount
    }

    var completionRate: Double {
        guard targetCount > 0 else { return 0 }
        return min(1.0, Double(currentCount) / Double(targetCount))
    }

    var isCollectionComplete: Bool {
        currentCount >= targetCount
    }

    var discoveryCountLabel: String {
        let count = currentCount
        return count == 1 ? "1 discovery" : "\(count) discoveries"
    }

    var progressStatusLabel: String {
        isCollectionComplete
            ? "COMPLETE ✨"
            : "\(Int((completionRate * 100).rounded()))% completed"
    }

    var progressDetailLabel: String {
        isCollectionComplete
            ? "COMPLETE ✨"
            : "\(currentCount) / \(targetCount) discoveries"
    }

    var latestRecordDate: Date? {
        records?.max(by: { $0.discoveryDate < $1.discoveryDate })?.discoveryDate
    }

    var sortedRecords: [MODIRecord] {
        (records ?? []).sorted { $0.discoveryDate > $1.discoveryDate }
    }

    var concept: Concept {
        Concept(
            id: id,
            title: title,
            emoji: emoji,
            description: collectionDescription,
            category: collectionCategory,
            type: collectionType == .custom ? .custom : .system
        )
    }
}

// MARK: - Factory

extension MODICollection {
    static func from(photoCollection: PhotoCollection, type: CollectionType) -> MODICollection {
        MODICollection(
            id: photoCollection.id,
            title: photoCollection.title,
            emoji: photoCollection.emoji,
            type: type,
            createdAt: .now,
            collectionDescription: photoCollection.description,
            missionPrompt: photoCollection.missionPrompt,
            themeColorHex: photoCollection.themeColorHex,
            category: photoCollection.category,
            sourceTemplateID: photoCollection.sourceTemplateID
        )
    }

    static func from(concept: Concept, missionPrompt: String? = nil, themeColorHex: String? = nil) -> MODICollection {
        MODICollection(
            id: concept.id,
            title: concept.title,
            emoji: concept.emoji,
            type: concept.type == .custom ? .custom : .system,
            createdAt: .now,
            collectionDescription: concept.description,
            missionPrompt: missionPrompt ?? concept.description,
            themeColorHex: themeColorHex ?? concept.themeColorHex,
            category: concept.category
        )
    }
}

// MARK: - Navigation

struct CollectionNavigationValue: Hashable {
    let id: UUID
}

extension MODICollection {
    var navigationValue: CollectionNavigationValue {
        CollectionNavigationValue(id: id)
    }
}
