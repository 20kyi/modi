import SwiftUI

struct OnboardingView: View {

    @Environment(NotificationManager.self) private var notificationManager
    @Environment(MissionManager.self) private var missionManager

    @State private var viewModel = OnboardingViewModel()
    @State private var wantsNotifications = false

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
            if viewModel.isLastPage {
                OnboardingNotificationOptIn(isEnabled: $wantsNotifications)
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                OnboardingPrimaryButton(title: "시작하기", action: completeOnboarding)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Color.clear
                    .frame(height: AppSpacing.minTouchTarget + AppSpacing.sm)
            }

            OnboardingPageIndicator(
                pageCount: viewModel.pages.count,
                currentIndex: viewModel.currentPageIndex
            )
        }
        .appScreenPadding()
        .padding(.bottom, AppSpacing.xl)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: viewModel.isLastPage)
    }

    private func completeOnboarding() {
        Task {
            if wantsNotifications {
                _ = await notificationManager.enableNotifications(missionManager: missionManager)
            }
            onComplete()
        }
    }
}

// MARK: - Notification Opt-In

struct OnboardingNotificationOptIn: View {
    @Binding var isEnabled: Bool

    var body: some View {
        Button {
            isEnabled.toggle()
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: isEnabled ? "bell.fill" : "bell")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isEnabled ? AppColor.Accent.primary : AppColor.Text.tertiary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("매일 오늘의 발견 알림 받기")
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.Text.primary)

                    Text("오늘의 Concept을 잊지 않도록 알려드릴게요")
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                }

                Spacer()

                Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isEnabled ? AppColor.Accent.primary : AppColor.Text.quaternary)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .frame(minHeight: AppSpacing.minTouchTarget)
            .appCardStyle(padding: 0)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isEnabled ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
        .environment(NotificationManager.mock)
        .environment(MissionManager.mock)
}
