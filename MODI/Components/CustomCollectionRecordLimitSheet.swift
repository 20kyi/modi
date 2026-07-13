import SwiftUI

// MARK: - CustomCollectionRecordLimitSheet

/// 무료 사용자가 커스텀 컬렉션에 새 기록을 추가하려 할 때 표시하는 MODI+ 안내 시트입니다.
struct CustomCollectionRecordLimitSheet: View {

    var onShowPremium: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Spacer()

                EmptyStateView(
                    icon: "photo.badge.plus",
                    title: "커스텀 컬렉션 기록 추가는 MODI+ 기능이에요",
                    message: """
                        구독이 해지되어도 기존 커스텀 컬렉션은 그대로 유지돼요. \
                        가장 먼저 만든 커스텀 컬렉션 1개에만 기록을 추가할 수 있어요.
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
            CustomCollectionRecordLimitSheet(onShowPremium: {})
        }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            CustomCollectionRecordLimitSheet(onShowPremium: {})
        }
        .preferredColorScheme(.dark)
}
