import SwiftUI

// MARK: - RecommendedCollectionTemplate

/// 홈에서 추천하는 커스텀 컬렉션 템플릿.
struct RecommendedCollectionTemplate: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let emoji: String
    let missionPrompt: String
    let themeColorHex: String

    var themeColor: Color { Color(hex: themeColorHex) }
}

// MARK: - Templates

extension RecommendedCollectionTemplate {

    static let all: [RecommendedCollectionTemplate] = [
        RecommendedCollectionTemplate(
            id: "daily-workout",
            title: "운동",
            subtitle: "움직인 순간을 기록해요",
            icon: "figure.run",
            emoji: "🏃",
            missionPrompt: "운동하는 모습을 찍으세요",
            themeColorHex: "F5E4DC"
        ),
        RecommendedCollectionTemplate(
            id: "daily-study",
            title: "스터디",
            subtitle: "공부한 하루를 남겨요",
            icon: "book.fill",
            emoji: "📚",
            missionPrompt: "공부하는 모습을 찍으세요",
            themeColorHex: "E4E8F5"
        ),
        RecommendedCollectionTemplate(
            id: "daily-food",
            title: "음식",
            subtitle: "오늘 먹은 맛있는 순간들",
            icon: "fork.knife",
            emoji: "🍽️",
            missionPrompt: "오늘의 음식을 찍으세요",
            themeColorHex: "F5EDE0"
        )
    ]
}
