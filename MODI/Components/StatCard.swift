import SwiftUI

struct StatCard: View {

    let value: String
    let label: String

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(AppFont.title3)
                .foregroundStyle(AppColor.Text.primary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)

            Text(label)
                .font(AppFont.caption1)
                .foregroundStyle(AppColor.Text.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .background(
            AppColor.Background.secondary,
            in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
        )
    }
}

#Preview {
    HStack(spacing: AppSpacing.sm) {
        StatCard(value: "20", label: "총 기록")
        StatCard(value: "5", label: "컨셉")
        StatCard(value: "7일", label: "연속 기록")
    }
    .appScreenPadding()
    .appScreenBackground()
}
