import SwiftUI

// MARK: - ThemeSelectionView

struct ThemeSelectionView: View {

    @Environment(ThemeManager.self) private var themeManager
    @Environment(PremiumManager.self) private var premiumManager
    @State private var isShowingPremium = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("앱 전체 분위기를 바꿔보세요. 추억을 기록하는 나만의 공간을 꾸며볼 수 있어요.")
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 0) {
                    ForEach(Array(AppTheme.allCases.enumerated()), id: \.element.id) { index, theme in
                        themeRow(theme)

                        if index < AppTheme.allCases.count - 1 {
                            themeDivider
                        }
                    }
                }
                .appCardStyle(padding: 0)
            }
            .appScreenPadding()
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .appGroupedBackground()
        .navigationTitle("테마")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColor.Background.primary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(isPresented: $isShowingPremium) {
            PremiumView()
        }
    }

    private func themeRow(_ theme: AppTheme) -> some View {
        let definition = theme.definition
        let isSelected = themeManager.selectedTheme == theme
        let isLocked = definition.isPremium && !premiumManager.isPremium

        return Button {
            if isLocked {
                isShowingPremium = true
            } else {
                themeManager.setTheme(theme, isPremium: premiumManager.isPremium)
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                themePreview(definition.colors)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(definition.displayName)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.Text.primary)

                    if definition.isPremium {
                        Text("MODI+ 테마")
                            .font(AppFont.caption2)
                            .foregroundStyle(AppColor.Accent.highlight)
                    }
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColor.Accent.highlight)
                } else if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColor.Text.tertiary)
                } else if definition.isPremium {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColor.Accent.highlight.opacity(0.85))
                }
            }
            .settingsRowStyle()
            .background(AppColor.Surface.card)
            .opacity(isLocked ? 0.72 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(definition.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isLocked ? "MODI+ 프리미엄 전용 테마" : "")
    }

    private func themePreview(_ colors: ThemeColors) -> some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(colors.background)
                .frame(width: 14, height: 28)
                .overlay {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(colors.borderDefault, lineWidth: 0.5)
                }

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(colors.primary)
                .frame(width: 10, height: 28)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(colors.accent)
                .frame(width: 8, height: 28)
        }
        .padding(.horizontal, AppSpacing.xxs)
    }

    private var themeDivider: some View {
        Divider()
            .padding(.leading, AppSpacing.lg + 52)
            .background(AppColor.Surface.card)
    }
}

// MARK: - Preview

#Preview("Light Theme Selected") {
    NavigationStack {
        ThemeSelectionView()
    }
    .environment(ThemeManager.shared)
    .environment(PremiumManager.shared)
    .onAppear {
        ThemeManager.shared.setTheme(.light)
    }
    .preferredColorScheme(.light)
}

#Preview("Pastel Diary Selected") {
    NavigationStack {
        ThemeSelectionView()
    }
    .environment(ThemeManager.shared)
    .environment(PremiumManager.mock)
    .onAppear {
        PremiumManager.mock.setDeveloperPremiumEnabled(true)
        ThemeManager.shared.setTheme(.pastelDiary, isPremium: true)
    }
    .preferredColorScheme(.light)
}

#Preview("Midnight Film Selected") {
    NavigationStack {
        ThemeSelectionView()
    }
    .environment(ThemeManager.shared)
    .environment(PremiumManager.mock)
    .onAppear {
        PremiumManager.mock.setDeveloperPremiumEnabled(true)
        ThemeManager.shared.setTheme(.midnightFilm, isPremium: true)
    }
    .preferredColorScheme(.dark)
}

#Preview("Locked Premium Themes") {
    NavigationStack {
        ThemeSelectionView()
    }
    .environment(ThemeManager.shared)
    .environment(PremiumManager(storage: UserDefaults(suiteName: "theme-selection-locked-preview")!))
    .onAppear {
        ThemeManager.shared.setTheme(.light)
    }
    .preferredColorScheme(.light)
}
