import SwiftUI

struct RecentDiscoveryView: View {

    let discoveries: [RecentDiscovery]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("최근 발견")
                .font(AppFont.title3)
                .foregroundStyle(AppColor.Text.primary)

            VStack(spacing: AppSpacing.sm) {
                ForEach(discoveries) { discovery in
                    discoveryRow(discovery)
                }
            }
        }
    }

    private func discoveryRow(_ discovery: RecentDiscovery) -> some View {
        HStack(spacing: AppSpacing.md) {
            Text(discovery.emoji)
                .font(.system(size: 24))
                .frame(width: 48, height: 48)
                .background(
                    discovery.themeColor.opacity(0.5),
                    in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                )

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(discovery.title)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Text.primary)

                Text(discovery.subtitle)
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
            }

            Spacer()

            Text(discovery.relativeDate)
                .font(AppFont.caption1)
                .foregroundStyle(AppColor.Text.tertiary)
        }
        .padding(AppSpacing.md)
        .background(
            AppColor.Surface.card,
            in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        )
        .shadow(color: AppShadow.subtle.color, radius: AppShadow.subtle.radius, x: 0, y: AppShadow.subtle.yOffset)
    }
}

#Preview {
    RecentDiscoveryView(discoveries: RecentDiscovery.mockList)
        .appScreenPadding()
        .appScreenBackground()
}
