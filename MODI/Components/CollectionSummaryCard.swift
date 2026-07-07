import SwiftUI

struct CollectionSummaryCard: View {

    let summary: ProfileCollectionSummary

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Text(summary.emoji)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(
                    AppColor.Background.secondary,
                    in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                )

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(summary.title)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Text.primary)

                Text("\(summary.momentCount)개의 순간")
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.Text.tertiary)
        }
        .padding(AppSpacing.lg)
        .background(
            AppColor.Surface.card,
            in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        )
        .shadow(color: AppShadow.subtle.color, radius: AppShadow.subtle.radius, x: 0, y: AppShadow.subtle.yOffset)
    }
}

#Preview {
    VStack(spacing: AppSpacing.sm) {
        ForEach(ProfileCollectionSummary.mockList) { summary in
            CollectionSummaryCard(summary: summary)
        }
    }
    .appScreenPadding()
    .appScreenBackground()
}
