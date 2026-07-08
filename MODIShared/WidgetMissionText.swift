import Foundation

enum WidgetDayKey {
    static func forDate(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    static var today: String { forDate(.now) }
}

enum WidgetMissionText {
    /// 위젯에 표시할 오늘의 미션 문구.
    static func message(for conceptTitle: String) -> String {
        switch conceptTitle {
        case "Pink Love":
            return "오늘은 분홍빛을 찾아보세요."
        case "Blue Mood":
            return "오늘은 파란색을 찾아보세요."
        case "Purple Dream":
            return "오늘은 보라빛을 찾아보세요."
        case "Yellow Day":
            return "오늘은 노란색을 찾아보세요."
        case "Green Life":
            return "오늘은 초록빛을 찾아보세요."
        case "White Moment":
            return "오늘은 하얀 순간을 찾아보세요."
        case "Cloud Hunter":
            return "오늘은 구름을 찾아보세요."
        case "Little Plant":
            return "오늘은 식물을 찾아보세요."
        case "Flower Diary":
            return "오늘은 꽃을 찾아보세요."
        case "Animal Friend":
            return "오늘은 동물을 찾아보세요."
        case "Sky Time":
            return "오늘은 밤하늘을 찾아보세요."
        default:
            return "오늘은 \(conceptTitle)을(를) 찾아보세요."
        }
    }
}
