import SwiftUI

struct OnboardingView: View {

    @State private var viewModel = OnboardingViewModel()
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            pager
            footer
        }
        .appScreenBackground()
    }

    // MARK: - Pager

    private var pager: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(viewModel.pages) { page in
                    OnboardingPageContent(
                        page: page,
                        isActive: page.id == viewModel.currentPageIndex
                    )
                    .containerRelativeFrame(.horizontal)
                    .id(page.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: Binding(
            get: { viewModel.currentPageIndex },
            set: { newValue in
                if let newValue {
                    viewModel.selectPage(newValue)
                }
            }
        ))
        .scrollIndicators(.hidden)
        .animation(.spring(response: 0.5, dampingFraction: 0.86), value: viewModel.currentPageIndex)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: AppSpacing.xxl) {
            OnboardingPageIndicator(
                pageCount: viewModel.pages.count,
                currentIndex: viewModel.currentPageIndex
            )

            if viewModel.isLastPage {
                OnboardingPrimaryButton(title: "시작하기", action: onComplete)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Color.clear
                    .frame(height: AppSpacing.minTouchTarget + AppSpacing.sm)
            }
        }
        .appScreenPadding()
        .padding(.bottom, AppSpacing.xl)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: viewModel.isLastPage)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}
