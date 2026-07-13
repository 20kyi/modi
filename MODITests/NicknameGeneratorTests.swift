import Foundation
import Testing
@testable import MODI

struct NicknameGeneratorTests {

    @Test func generatesNicknameFromAdjectiveAndNoun() {
        let nickname = NicknameGenerator.generateRandomNickname()

        let hasKnownPrefix = NicknameGenerator.adjectives.contains { nickname.hasPrefix($0) }
        #expect(hasKnownPrefix)

        let matchedNoun = NicknameGenerator.nouns.first { nickname.hasSuffix($0) }
        #expect(matchedNoun != nil)
    }

    @Test func avoidsDuplicateNicknamesWhenPossible() {
        let existing = Set(["노을토끼", "달빛고양이"])
        let nickname = NicknameGenerator.generateRandomNickname(excluding: existing)

        #expect(!existing.contains(nickname))
    }

    @Test func appendsNumericSuffixWhenAllCombinationsAreTaken() {
        let allCombinations = Set(
            NicknameGenerator.adjectives.flatMap { adjective in
                NicknameGenerator.nouns.map { noun in
                    adjective + noun
                }
            }
        )

        let nickname = NicknameGenerator.generateRandomNickname(excluding: allCombinations)

        #expect(!allCombinations.contains(nickname))
        #expect(nickname.count >= 3)
    }
}
