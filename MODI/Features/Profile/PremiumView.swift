import SwiftUI

struct PremiumView: View {

    @Environment(PremiumManager.self) private var premiumManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                statusSection

                #if DEBUG
                developerSection
                #endif
            }
            .appScreenPadding()
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .appGroupedBackground()
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColor.Background.primary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "MODI+")

            settingsValueRow(
                icon: "crown.fill",
                title: premiumManager.isPremium ? "프리미엄 이용 중" : "프리미엄 미가입",
                subtitle: premiumManager.isPremium
                    ? "MODI+ 기능을 사용할 수 있어요"
                    : "MODI+로 더 풍부한 기록 경험을 만나보세요"
            )
            .appCardStyle(padding: 0)
        }
    }

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
    #endif

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(AppFont.title3)
            .foregroundStyle(AppColor.Text.primary)
    }

    private func settingsValueRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            rowIcon(icon)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.Text.primary)

                Text(subtitle)
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .settingsRowStyle()
        .background(AppColor.Surface.card)
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
                rowIcon(icon)

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
                    .tint(AppColor.Accent.primary)
                    .allowsHitTesting(false)
            }
            .settingsRowStyle()
            .background(AppColor.Surface.card)
        }
        .buttonStyle(.plain)
    }

    private func rowIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(AppColor.Accent.primary)
            .frame(width: 28)
    }
}

#Preview("Premium 비활성 · Light") {
    NavigationStack {
        PremiumView()
    }
    .environment(PremiumManager.shared)
    .preferredColorScheme(.light)
}

#Preview("Premium 활성 · Dark") {
    let manager = PremiumManager(storage: UserDefaults(suiteName: "premium-view-preview-active")!)
    manager.setDeveloperPremiumEnabled(true)

    return NavigationStack {
        PremiumView()
    }
    .environment(manager)
    .preferredColorScheme(.dark)
}
