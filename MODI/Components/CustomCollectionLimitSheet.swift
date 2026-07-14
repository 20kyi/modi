import SwiftUI

// MARK: - CustomCollectionLimitSheet

/// 무료 사용자가 커스텀 컬렉션 생성 한도에 도달했을 때 표시하는 MODI+ 안내 시트입니다.
struct CustomCollectionLimitSheet: View {

    var onShowPremium: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Spacer()

                EmptyStateView(
                    icon: "folder.badge.plus",
                    title: "커스텀 컬렉션 한도에 도달했어요",
                    message: """
                        무료에서는 커스텀 컬렉션을 1개까지 만들 수 있습니다. \
                        MODI+에서 원하는 만큼 컬렉션을 만들어 추억을 정리해보세요.
                        """
                )

                benefitSummary

                Spacer()

                VStack(spacing: AppSpacing.sm) {
                    Button("MODI+ 알아보기") {
                        dismiss()
                        onShowPremium()
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("닫기") {
                        dismiss()
                    }
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Text.secondary)
                }
            }
            .appScreenPadding()
            .padding(.bottom, AppSpacing.xl)
            .appScreenBackground()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var benefitSummary: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("MODI+로 더 자유롭게 기록해요")
                .font(AppFont.subheadline)
                .foregroundStyle(AppColor.Text.primary)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                benefitRow("커스텀 컬렉션을 원하는 만큼 만들 수 있어요")
                benefitRow("컬렉션별 미션으로 사진을 깔끔하게 모을 수 있어요")
                benefitRow("내 취향에 맞는 기록 루틴을 오래 유지할 수 있어요")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.Accent.soft, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.Accent.highlight)
                .padding(.top, 1)

            Text(text)
                .font(AppFont.footnote)
                .foregroundStyle(AppColor.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview("Light") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            CustomCollectionLimitSheet(onShowPremium: {})
        }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            CustomCollectionLimitSheet(onShowPremium: {})
        }
        .preferredColorScheme(.dark)
}
