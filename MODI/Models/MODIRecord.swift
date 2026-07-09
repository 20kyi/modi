import Foundation
import SwiftData

// MARK: - MODIRecord

/// 꾸민 사진과 Concept 정보를 함께 저장하는 기록.
@Model
final class MODIRecord {

    var id: UUID
    /// 서버 records.id (UUID 문자열). 비로그인 로컬 데이터는 nil일 수 있음.
    var serverId: String?
    @Attribute(.externalStorage)
    var imageData: Data
    @Attribute(.externalStorage)
    var originalImageData: Data?
    var editorStateData: Data?
    /// Concept 식별자. `Concept.id` 및 `PhotoCollection.id`와 동일.
    @Attribute(originalName: "missionId")
    var conceptId: UUID
    @Attribute(originalName: "missionTitle")
    var conceptTitle: String
    @Attribute(originalName: "missionEmoji")
    var conceptEmoji: String
    var createdAt: Date
    /// 실제 발견 날짜. nil이면 `createdAt`을 발견 날짜로 취급합니다.
    var recordDate: Date?
    /// 기존 데이터 마이그레이션 호환을 위해 optional. nil이면 false로 취급.
    var isEdited: Bool?
    var collection: MODICollection?

    init(
        id: UUID = UUID(),
        imageData: Data,
        conceptId: UUID,
        conceptTitle: String,
        conceptEmoji: String,
        createdAt: Date = .now,
        recordDate: Date? = nil,
        isEdited: Bool = false
    ) {
        self.id = id
        self.imageData = imageData
        self.conceptId = conceptId
        self.conceptTitle = conceptTitle
        self.conceptEmoji = conceptEmoji
        self.createdAt = createdAt
        self.recordDate = recordDate.map { Calendar.current.startOfDay(for: $0) }
        self.isEdited = isEdited
    }
}

extension MODIRecord {
    var wasEdited: Bool { isEdited ?? false }

    /// 캘린더·스트릭 등에 사용하는 실제 발견 날짜.
    var discoveryDate: Date {
        Calendar.current.startOfDay(for: recordDate ?? createdAt)
    }
}
