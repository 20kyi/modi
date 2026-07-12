import SwiftUI

// MARK: - EarnedTitlePresentation

struct EarnedTitlePresentation: Identifiable {
    let id = UUID()
    let earnedTitle: ProfileHighestTitle
}

// MARK: - EarnedTitleModalPresenter

@MainActor
@Observable
final class EarnedTitleModalPresenter {

    var presentation: EarnedTitlePresentation?

    func present(_ earnedTitle: ProfileHighestTitle) {
        presentation = EarnedTitlePresentation(earnedTitle: earnedTitle)
    }

    func dismiss() {
        presentation = nil
    }

    static let mock = EarnedTitleModalPresenter()
}

// MARK: - EarnedTitleDetailModal

/// 획득한 배너를 탭했을 때 획득 맥락을 보여주는 중앙 모달.
struct EarnedTitleDetailModal: View {

    let earnedTitle: ProfileHighestTitle
    var onDismiss: () -> Void

    @State private var showsBackground = false
    @State private var isCardVisible = false

    var body: some View {
        ZStack {
            if showsBackground {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }
            }

            modalCard
                .scaleEffect(isCardVisible ? 1 : 0.92)
                .opacity(isCardVisible ? 1 : 0)
        }
        .onAppear {
            showsBackground = true
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                isCardVisible = true
            }
        }
    }

    // MARK: - Modal Card

    /// 타이틀 배지 상세 모달 카드
    private var modalCard: some View {
        VStack(spacing: AppSpacing.lg) {
            HStack {
                Spacer(minLength: 0)

                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AppColor.Text.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("닫기")
            }

            collectionSection
            achievementSection
            acquisitionSection
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.lg)
        .padding(.bottom, AppSpacing.xxxl)
        .background(AppColor.Background.primary, in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .appShadow(.medium)
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - Content

    // MARK: - Collection Section

    /// 타이틀 이미지
    private var collectionSection: some View {
        VStack(spacing: AppSpacing.sm) {
            Text(earnedTitle.emoji)
                .font(.system(size: 40))

            Text(earnedTitle.collectionTitle)
                .font(AppFont.headline)
                .foregroundStyle(AppColor.Text.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Achievement Section

    /// 타이틀 획득 조건
    private var achievementSection: some View {
        Text(earnedTitle.achievementDescription)
            .font(AppFont.footnote) // 타이틀 획득 조건
            .foregroundStyle(AppColor.Text.primary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Acquisition Section

    /// 타이틀 획득 일자
    private var acquisitionSection: some View {
        Text(formattedAcquiredDate)
            .font(AppFont.caption2)
            .foregroundStyle(AppColor.Text.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Helpers

    /// 타이틀 획득 일자 포맷팅
    private var formattedAcquiredDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: earnedTitle.acquiredDate)
    }

    private func dismiss() {
        showsBackground = false
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            isCardVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview("Light") {
    ZStack {
        AppColor.Background.primary.ignoresSafeArea()
        EarnedTitleDetailModal(earnedTitle: .mock, onDismiss: {})
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    ZStack {
        AppColor.Background.primary.ignoresSafeArea()
        EarnedTitleDetailModal(earnedTitle: .mock, onDismiss: {})
    }
    .preferredColorScheme(.dark)
}
