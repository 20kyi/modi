import Foundation

/// 감성적인 기본 닉네임을 [형용사/감성 단어] + [동물/자연/사물] 조합으로 생성합니다.
enum NicknameGenerator {
    static let adjectives: [String] = [
        "노을",
        "달빛",
        "초록",
        "푸른",
        "따뜻한",
        "포근한",
        "새벽",
        "여름",
        "겨울",
        "산책",
        "반짝",
        "고요한",
        "벚꽃",
        "숲속",
        "은하",
        "민트",
        "작은",
    ]

    static let nouns: [String] = [
        "토끼",
        "고양이",
        "여우",
        "다람쥐",
        "오리",
        "사슴",
        "참새",
        "고래",
        "바람",
        "구름",
        "숲",
        "별",
        "바다",
        "달",
    ]

    /// 랜덤 닉네임을 생성합니다.
    /// - Parameter existingNicknames: 이미 사용 중인 닉네임 집합. 중복 시 재시도하고, 불가하면 2자리 숫자를 붙입니다.
    static func generateRandomNickname(
        excluding existingNicknames: Set<String> = []
    ) -> String {
        let maxAttempts = adjectives.count * nouns.count

        for _ in 0..<maxAttempts {
            let candidate = combineRandom()
            if !existingNicknames.contains(candidate) {
                return candidate
            }
        }

        return makeUniqueWithNumericSuffix(
            base: combineRandom(),
            excluding: existingNicknames
        )
    }

    private static func combineRandom() -> String {
        let adjective = adjectives.randomElement() ?? adjectives[0]
        let noun = nouns.randomElement() ?? nouns[0]
        return adjective + noun
    }

    private static func makeUniqueWithNumericSuffix(
        base: String,
        excluding existingNicknames: Set<String>
    ) -> String {
        for _ in 0..<100 {
            let suffix = String(format: "%02d", Int.random(in: 0...99))
            let candidate = base + suffix
            if !existingNicknames.contains(candidate) {
                return candidate
            }
        }

        return base + String(format: "%02d", Int.random(in: 0...99))
    }
}
