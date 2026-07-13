import SwiftUI

// MARK: - ThemePreviewCard

struct ThemePreviewCard: View {

    let highlight: PremiumThemeHighlight

    private var colors: ThemeColors { highlight.theme.definition.colors }

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.sm) {
            previewSquare

            HStack(spacing: AppSpacing.xs) {
                Text(highlight.emoji)
                    .font(.system(size: 13))

                Text(highlight.name)
                    .font(AppFont.caption1)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var previewSquare: some View {
        VStack(spacing: 0) {
            colors.background
                .frame(maxWidth: .infinity)
                .aspectRatio(1 / 0.28, contentMode: .fit)

            colors.surface
                .frame(maxWidth: .infinity)
                .aspectRatio(1 / 0.52, contentMode: .fit)

            Text("Button")
                .font(.system(size: 7, weight: .semibold))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(colors.onAccent)
                .frame(maxWidth: .infinity)
                .aspectRatio(1 / 0.20, contentMode: .fit)
                .background(colors.primary)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(colors.borderDefault, lineWidth: 0.5)
        }
    }
}

// MARK: - Preview

#Preview("Theme Preview Cards · Light") {
    HStack(alignment: .top, spacing: AppSpacing.md) {
        ForEach(PremiumBenefitCatalog.premiumThemes) { theme in
            ThemePreviewCard(highlight: theme)
        }
    }
    .appScreenPadding()
    .appGroupedBackground()
    .preferredColorScheme(.light)
}

#Preview("Midnight Film") {
    ThemePreviewCard(highlight: PremiumBenefitCatalog.premiumThemes[1])
        .padding()
        .appGroupedBackground()
        .preferredColorScheme(.dark)
}
