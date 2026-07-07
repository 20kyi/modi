import SwiftUI

struct EmptyStateView: View {

    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(AppColor.Accent.primary.opacity(0.6))

            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.Text.primary)

                Text(message)
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.Accent.primary)
                }
                .padding(.top, AppSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
        .padding(.horizontal, AppSpacing.lg)
        .background(AppColor.Background.secondary, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    EmptyStateView(
        icon: "photo.on.rectangle.angled",
        title: "아직 제작한 아이템이 없어요",
        message: "첫 번째 아이템을 만들어보세요.",
        actionTitle: "만들기",
        action: {}
    )
    .appScreenPadding()
    .appScreenBackground()
}
