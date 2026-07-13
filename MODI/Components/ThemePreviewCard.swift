import SwiftUI

// MARK: - ThemePreviewCard

struct ThemePreviewCard: View {

    let highlight: PremiumThemeHighlight

    private var colors: ThemeColors { highlight.theme.definition.colors }

    private let size: CGFloat = 112

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.sm) {
            previewSquare

            HStack(spacing: AppSpacing.xs) {
                Text(highlight.emoji)
                    .font(.system(size: 13))

                Text(highlight.name)
                    .font(AppFont.caption1)
                    .foregroundStyle(AppColor.Text.primary)
            }
        }
        .frame(width: size)
    }

    private var previewSquare: some View {
        VStack(spacing: 0) {
            colors.background
                .frame(height: size * 0.28)

            colors.surface
                .frame(height: size * 0.52)

            Text("Button")
                .font(.system(size: 7, weight: .semibold))
                .foregroundStyle(colors.onAccent)
                .frame(maxWidth: .infinity)
                .frame(height: size * 0.20)
                .background(colors.primary)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(colors.borderDefault, lineWidth: 0.5)
        }
    }
}

// MARK: - Preview

#Preview("Theme Preview Cards · Light") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: AppSpacing.md) {
            ForEach(PremiumBenefitCatalog.premiumThemes) { theme in
                ThemePreviewCard(highlight: theme)
            }
        }
        .padding()
    }
    .appGroupedBackground()
    .preferredColorScheme(.light)
}

#Preview("Midnight Film") {
    ThemePreviewCard(highlight: PremiumBenefitCatalog.premiumThemes[1])
        .padding()
        .appGroupedBackground()
        .preferredColorScheme(.dark)
}
