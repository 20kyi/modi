import Foundation
import SwiftData

// MARK: - MODIRecord

/// 꾸민 사진과 미션 정보를 함께 저장하는 기록.
@Model
final class MODIRecord {

    var id: UUID
    @Attribute(.externalStorage)
    var imageData: Data
    /// 미션(컬렉션) 식별자. `DailyMission.collectionID`와 동일.
    var missionId: UUID
    var missionTitle: String
    var missionEmoji: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        imageData: Data,
        missionId: UUID,
        missionTitle: String,
        missionEmoji: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.imageData = imageData
        self.missionId = missionId
        self.missionTitle = missionTitle
        self.missionEmoji = missionEmoji
        self.createdAt = createdAt
    }
}
