import SwiftUI

@Observable
final class OnboardingViewModel {

    // MARK: - State

    var currentPageIndex = 0

    let pages: [OnboardingPageData] = [
        OnboardingPageData(
            id: 0,
            title: "세상은\n생각보다\n다채롭습니다.",
            subtitle: "평범한 하루도 시선을 바꾸면 새로운 컬렉션이 됩니다.",
            visual: .textOnly
        ),
        OnboardingPageData(
            id: 1,
            title: "이번 달에는\n하늘을\n모아보세요.",
            subtitle: "매달 하나의 주제.\n매일 한 장.",
            visual: .heroImage
        ),
        OnboardingPageData(
            id: 2,
            title: "한 달이 지나면\n하나의\n컬렉션이 됩니다.",
            subtitle: "평범했던 순간들이 특별한 기록이 됩니다.",
            visual: .photoGrid
        ),
        OnboardingPageData(
            id: 3,
            title: "당신의\n첫 번째\n발견을 시작하세요.",
            subtitle: "오늘의 한 장이\n한 달을 완성합니다.",
            visual: .textOnly
        )
    ]

    var isLastPage: Bool {
        currentPageIndex == pages.count - 1
    }

    // MARK: - Actions

    func selectPage(_ index: Int) {
        guard pages.indices.contains(index) else { return }
        currentPageIndex = index
    }
}
