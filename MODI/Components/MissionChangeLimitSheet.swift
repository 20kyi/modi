import SwiftUI

// MARK: - MissionChangeLimitSheet

/// 무료 사용자가 오늘의 미션 변경 한도에 도달했을 때 표시하는 MODI+ 안내 시트입니다.
struct MissionChangeLimitSheet: View {

    var onShowPremium: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Spacer()

                EmptyStateView(
                    icon: "arrow.triangle.2.circlepath",
                    title: "오늘의 미션 변경 횟수를 모두 사용했어요",
                    message: """
                        무료에서는 하루에 한 번 미션을 변경할 수 있습니다. \
                        MODI+에서는 하루 최대 3회까지 원하는 미션으로 변경할 수 있습니다.
                        """
                )

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
}

// MARK: - Preview

#Preview("Light") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            MissionChangeLimitSheet(onShowPremium: {})
        }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            MissionChangeLimitSheet(onShowPremium: {})
        }
        .preferredColorScheme(.dark)
}
