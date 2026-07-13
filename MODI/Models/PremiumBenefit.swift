import Foundation

// MARK: - PremiumBenefit

struct PremiumBenefit: Identifiable {
    let id: String
    let icon: String
    let title: String
    let description: String
    var footnote: String?
    var includedThemes: [PremiumThemeHighlight]?
}

struct PremiumThemeHighlight: Identifiable {
    let id: String
    let emoji: String
    let name: String
    let theme: AppTheme
}

// MARK: - PremiumBenefitCatalog

enum PremiumBenefitCatalog {

    static let benefits: [PremiumBenefit] = [
        PremiumBenefit(
            id: "past-discovery",
            icon: "📅",
            title: "과거의 발견 다시 채우기",
            description: """
                지나간 날짜에도 새로운 발견 기록을 추가하고 \
                놓친 순간을 다시 기록할 수 있습니다.
                """
        ),
        PremiumBenefit(
            id: "custom-collections",
            icon: "📂",
            title: "커스텀 컬렉션 확장",
            description: """
                나만의 컬렉션을 더 자유롭게 만들고 \
                추억을 원하는 방식으로 정리할 수 있습니다.
                """,
            footnote: "무료: 커스텀 컬렉션 1개 · MODI+: 추가 컬렉션 생성"
        ),
        PremiumBenefit(
            id: "premium-themes",
            icon: "🎨",
            title: "프리미엄 테마",
            description: """
                MODI를 나만의 분위기로 꾸밀 수 있는 \
                감성적인 테마를 제공합니다.
                """,
            includedThemes: premiumThemes
        ),
        PremiumBenefit(
            id: "mission-reroll",
            icon: "🎯",
            title: "더 자유로운 오늘의 미션",
            description: """
                하루 최대 3회까지 미션을 변경하며 \
                나에게 맞는 기록을 만들 수 있습니다.
                """
        ),
    ]

    static let premiumThemes: [PremiumThemeHighlight] = [
        PremiumThemeHighlight(
            id: "pastel-diary",
            emoji: "🌸",
            name: "Pastel Diary",
            theme: .pastelDiary
        ),
        PremiumThemeHighlight(
            id: "midnight-film",
            emoji: "🌌",
            name: "Midnight Film",
            theme: .midnightFilm
        ),
        PremiumThemeHighlight(
            id: "nature-archive",
            emoji: "🌱",
            name: "Nature Archive",
            theme: .natureArchive
        ),
    ]
}
