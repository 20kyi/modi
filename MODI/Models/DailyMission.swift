import Foundation

// MARK: - DailyMission

/// 하루에 하나씩 배정되는 사진 미션.
struct DailyMission: Codable, Equatable, Identifiable {
    let id: UUID
    let collectionID: UUID
    let prompt: String
    let date: Date

    init(collectionID: UUID, prompt: String, date: Date = .now) {
        self.id = UUID()
        self.collectionID = collectionID
        self.prompt = prompt
        self.date = Calendar.current.startOfDay(for: date)
    }

    var dayKey: String {
        Self.dayKey(for: date)
    }

    static func dayKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}

// MARK: - MissionEntry

/// 완료한 미션 기록. 해당 컬렉션에 사진이 쌓임.
struct MissionEntry: Codable, Equatable, Identifiable {
    let id: UUID
    let collectionID: UUID
    let missionDate: Date
    let completedAt: Date
    let prompt: String

    init(collectionID: UUID, missionDate: Date, prompt: String, completedAt: Date = .now) {
        self.id = UUID()
        self.collectionID = collectionID
        self.missionDate = Calendar.current.startOfDay(for: missionDate)
        self.completedAt = completedAt
        self.prompt = prompt
    }
}
