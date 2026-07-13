import SwiftUI

// MARK: - BenefitCard

struct BenefitCard: View {

    let benefit: PremiumBenefit

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                benefitIcon

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        Text(benefit.title)
                            .font(AppFont.headline)
                            .foregroundStyle(AppColor.Text.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: AppSpacing.sm)

                        PremiumBadge()
                    }

                    Text(benefit.description)
                        .font(AppFont.subheadline)
                        .foregroundStyle(AppColor.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let footnote = benefit.footnote {
                Text(footnote)
                    .font(AppFont.caption1)
                    .foregroundStyle(AppColor.Text.tertiary)
                    .padding(.leading, 48 + AppSpacing.md)
            }

            if let themes = benefit.includedThemes, !themes.isEmpty {
                themeChips(themes)
                    .padding(.leading, 48 + AppSpacing.md)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(shadow: .medium)
    }

    private var benefitIcon: some View {
        Text(benefit.icon)
            .font(.system(size: 26))
            .frame(width: 48, height: 48)
            .background(
                AppColor.Accent.soft,
                in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
            )
            .accessibilityHidden(true)
    }

    private func themeChips(_ themes: [PremiumThemeHighlight]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("포함 테마")
                .font(AppFont.caption2)
                .foregroundStyle(AppColor.Text.tertiary)

            FlowLayout(spacing: AppSpacing.sm) {
                ForEach(themes) { theme in
                    HStack(spacing: AppSpacing.xs) {
                        Text(theme.emoji)
                            .font(.system(size: 13))

                        Text(theme.name)
                            .font(AppFont.caption1)
                            .foregroundStyle(AppColor.Text.primary)
                    }
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(
                        AppColor.Background.secondary,
                        in: Capsule(style: .continuous)
                    )
                }
            }
        }
    }
}

// MARK: - PremiumBadge

struct PremiumBadge: View {

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: "crown.fill")
                .font(.system(size: 9, weight: .semibold))

            Text("MODI+")
                .font(AppFont.caption2.weight(.semibold))
        }
        .foregroundStyle(AppColor.Semantic.warning)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .background(
            AppColor.Semantic.warning.opacity(0.12),
            in: Capsule(style: .continuous)
        )
        .accessibilityLabel("MODI+ 프리미엄")
    }
}

// MARK: - FlowLayout

private struct FlowLayout: Layout {

    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> ArrangementResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)

            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }

        let totalHeight = currentY + rowHeight
        return ArrangementResult(
            size: CGSize(width: maxWidth, height: totalHeight),
            positions: positions,
            sizes: sizes
        )
    }

    private struct ArrangementResult {
        let size: CGSize
        let positions: [CGPoint]
        let sizes: [CGSize]
    }
}

// MARK: - Preview

#Preview("Benefit Card · Light") {
    ScrollView {
        BenefitCard(benefit: PremiumBenefitCatalog.benefits[2])
            .appScreenPadding()
    }
    .appGroupedBackground()
    .preferredColorScheme(.light)
}

#Preview("Benefit Card · Dark") {
    ScrollView {
        BenefitCard(benefit: PremiumBenefitCatalog.benefits[1])
            .appScreenPadding()
    }
    .appGroupedBackground()
    .preferredColorScheme(.dark)
}
