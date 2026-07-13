import SwiftUI

// MARK: - ThemePreviewCard

struct ThemePreviewCard: View {

    let highlight: PremiumThemeHighlight

    private var colors: ThemeColors { highlight.theme.definition.colors }

    private enum Layout {
        static let innerPadding = AppSpacing.md
        static let referenceWidth: CGFloat = 260
        static let referenceHeight: CGFloat = 280
    }

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
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let inset = Layout.innerPadding
            let availableWidth = side - inset * 2
            let availableHeight = side - inset * 2
            let scale = min(
                availableWidth / Layout.referenceWidth,
                availableHeight / Layout.referenceHeight
            )

            ZStack {
                colors.background

                createViewPreview
                    .frame(width: Layout.referenceWidth)
                    .scaleEffect(scale, anchor: .center)
            }
            .padding(inset)
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(colors.borderDefault, lineWidth: 0.5)
        }
    }

    private var previewMission: DailyMission { .mock }

    private var createViewPreview: some View {
        VStack(spacing: AppSpacing.md) {
            themePreviewCardContainer

            Button {} label: {
                Label("사진 찍기", systemImage: "camera.fill")
            }
            .buttonStyle(ThemedPrimaryButtonStyle(colors: colors))
        }
        .background(colors.background)
    }

    private var themePreviewCardContainer: some View {
        RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
            .fill(previewMission.themeColor.opacity(0.45))
            .frame(maxWidth: .infinity, minHeight: 200)
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .strokeBorder(previewMission.themeColor.opacity(0.6), lineWidth: 1)
            }
            .shadow(color: colors.shadowMedium, radius: 8, x: 0, y: 4)
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
