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
    /// 오늘의 발견(미션) 후보 포함 여부.
    var isIncludedInMission: Bool = true

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
        targetCount: Int = 20,
        isIncludedInMission: Bool = true
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
        self.isIncludedInMission = isIncludedInMission
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

    var collectionProgress: CollectionProgress {
        CollectionProgress.make(conceptID: id, totalDiscoveries: currentCount)
    }

    var currentTitle: CollectionTitle? {
        collectionProgress.currentTitle
    }

    var currentTitleName: String? {
        currentTitle?.name
    }

    var progressionRate: Double {
        collectionProgress.progress
    }

    var discoveriesUntilNextTitle: Int? {
        collectionProgress.discoveriesUntilNext
    }

    var discoveryCountLabel: String {
        let count = currentCount
        return count == 1 ? "1 Discovery" : "\(count) Discoveries"
    }

    var nextTitleProgressLabel: String? {
        guard let until = discoveriesUntilNextTitle,
              let nextTitleName = ConceptTitleRegistry.nextTitleName(for: id, discoveries: currentCount)
        else { return nil }

        return "\(until) Discoveries until \(nextTitleName)"
    }

    var nextTitleCardLabel: String? {
        guard let until = discoveriesUntilNextTitle else { return nil }
        return "\(until) Discoveries"
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
            type: collectionType == .custom ? .custom : .system,
            missionPrompt: missionPrompt,
            themeColorHex: themeColorHex
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
            sourceTemplateID: photoCollection.sourceTemplateID,
            isIncludedInMission: photoCollection.isIncludedInMission
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
