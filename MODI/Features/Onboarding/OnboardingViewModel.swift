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
            title: "오늘은\n분홍색을\n찍어보세요.",
            subtitle: "매일 다른 미션.\n매일 한 장.",
            visual: .heroImage
        ),
        OnboardingPageData(
            id: 2,
            title: "미션마다\n컬렉션이 쌓입니다",
            subtitle: "분홍, 하늘, 밤하늘…\n사진이 모이면 나만의 컬렉션이 돼요.",
            visual: .photoGrid
        ),
        OnboardingPageData(
            id: 3,
            title: "당신의\n첫 번째\n발견을 시작하세요.",
            subtitle: "오늘의 미션으로\n첫 컬렉션을 시작해요.",
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
