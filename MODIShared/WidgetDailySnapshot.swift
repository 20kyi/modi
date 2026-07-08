import Foundation

struct WidgetDailySnapshot: Codable, Equatable {
    let dayKey: String
    let conceptTitle: String
    let conceptEmoji: String
    let missionMessage: String
    let themeColorHex: String
    let streakDays: Int
    let hasPhoto: Bool
    let updatedAt: Date

    static let placeholder = WidgetDailySnapshot(
        dayKey: WidgetDayKey.today,
        conceptTitle: "Cloud Hunter",
        conceptEmoji: "☁️",
        missionMessage: "오늘은 구름을 찾아보세요.",
        themeColorHex: "E4ECF4",
        streakDays: 0,
        hasPhoto: false,
        updatedAt: .now
    )
}
