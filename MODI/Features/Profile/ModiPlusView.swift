import SwiftUI

// MARK: - ModiPlusView

struct ModiPlusView: View {

    @Environment(PremiumManager.self) private var premiumManager

    private let benefits = PremiumBenefitCatalog.benefits
    private let premiumThemes = PremiumBenefitCatalog.premiumThemes

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                heroSection
                benefitsSection
                themePreviewSection

                #if DEBUG
                developerSection
                #endif
            }
            .appScreenPadding()
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .appGroupedBackground()
        .navigationTitle("MODI+")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColor.Background.primary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ctaSection
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.Semantic.warning)

                Text("MODI+")
                    .font(AppFont.Rounded.headline)
                    .foregroundStyle(AppColor.Semantic.warning)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                AppColor.Semantic.warning.opacity(0.12),
                in: Capsule(style: .continuous)
            )

            Text("나만의 순간을\n더 자유롭게 기록하세요")
                .font(AppFont.Rounded.title)
                .foregroundStyle(AppColor.Text.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("MODI+에서는 추억을 더 깊게 관리하고,\n나만의 방식으로 기록할 수 있습니다.")
                .font(AppFont.body)
                .foregroundStyle(AppColor.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.xl)
        .background(
            LinearGradient(
                colors: [
                    AppColor.Accent.soft.opacity(0.55),
                    AppColor.Surface.card,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .stroke(AppColor.Border.default, lineWidth: 0.75)
        }
        .appShadow(.subtle)
    }

    // MARK: - Benefits

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "MODI+ 혜택")

            VStack(spacing: AppSpacing.itemGap) {
                ForEach(benefits) { benefit in
                    BenefitCard(benefit: benefit)
                }
            }
        }
    }

    // MARK: - Theme Preview

    private var themePreviewSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "프리미엄 테마 미리보기")

            Text("감성적인 분위기로 MODI를 나만의 공간으로 꾸며보세요.")
                .font(AppFont.footnote)
                .foregroundStyle(AppColor.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: AppSpacing.md) {
                ForEach(premiumThemes) { theme in
                    ThemePreviewCard(highlight: theme)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, AppSpacing.xxs)
        }
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                // StoreKit 연결 예정
            } label: {
                Text("MODI+ 시작하기")
            }
            .buttonStyle(PrimaryButtonStyle())
            .appScreenPadding()
            .padding(.vertical, AppSpacing.md)
            .background(AppColor.Background.primary)
        }
    }

    // MARK: - Developer

    #if DEBUG
    private var developerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "개발자")

            VStack(spacing: 0) {
                settingsToggleRow(
                    icon: "hammer.fill",
                    title: "프리미엄 상태",
                    subtitle: "개발·테스트용 프리미엄 시뮬레이션",
                    isOn: Binding(
                        get: { premiumManager.isDeveloperPremiumEnabled },
                        set: { premiumManager.setDeveloperPremiumEnabled($0) }
                    )
                )
            }
            .appCardStyle(padding: 0)
        }
    }

    private func settingsToggleRow(
        icon: String,
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>
    ) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColor.Accent.highlight)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(title)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.Text.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(AppFont.footnote)
                            .foregroundStyle(AppColor.Text.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)

                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(AppColor.Accent.highlight)
                    .allowsHitTesting(false)
            }
            .settingsRowStyle()
            .background(AppColor.Surface.card)
        }
        .buttonStyle(.plain)
    }
    #endif

    // MARK: - Helpers

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(AppFont.title3)
            .foregroundStyle(AppColor.Text.primary)
    }
}

// MARK: - Preview

#Preview("MODI+ · Light") {
    NavigationStack {
        ModiPlusView()
    }
    .environment(PremiumManager.shared)
    .preferredColorScheme(.light)
}

#Preview("MODI+ · Dark") {
    NavigationStack {
        ModiPlusView()
    }
    .environment(PremiumManager.shared)
    .preferredColorScheme(.dark)
}
