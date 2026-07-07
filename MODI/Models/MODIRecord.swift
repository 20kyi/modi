import Foundation
import SwiftData

// MARK: - MODIRecord

/// 꾸민 사진과 Concept 정보를 함께 저장하는 기록.
@Model
final class MODIRecord {

    var id: UUID
    @Attribute(.externalStorage)
    var imageData: Data
    /// Concept 식별자. `Concept.id` 및 `PhotoCollection.id`와 동일.
    @Attribute(originalName: "missionId")
    var conceptId: UUID
    @Attribute(originalName: "missionTitle")
    var conceptTitle: String
    @Attribute(originalName: "missionEmoji")
    var conceptEmoji: String
    var createdAt: Date
    /// 기존 데이터 마이그레이션 호환을 위해 optional. nil이면 false로 취급.
    var isEdited: Bool?

    init(
        id: UUID = UUID(),
        imageData: Data,
        conceptId: UUID,
        conceptTitle: String,
        conceptEmoji: String,
        createdAt: Date = .now,
        isEdited: Bool = false
    ) {
        self.id = id
        self.imageData = imageData
        self.conceptId = conceptId
        self.conceptTitle = conceptTitle
        self.conceptEmoji = conceptEmoji
        self.createdAt = createdAt
        self.isEdited = isEdited
    }
}

extension MODIRecord {
    var wasEdited: Bool { isEdited ?? false }
}
