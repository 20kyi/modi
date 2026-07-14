import StoreKit
import SwiftUI

// MARK: - ModiPlusView

struct ModiPlusView: View {

    @Environment(AuthManager.self) private var authManager
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.openURL) private var openURL

    @State private var selectedOptionID = ModiPlusPurchaseOption.recommendedID
    @State private var isShowingLogin = false
    @State private var pendingActionAfterLogin: PendingPremiumAction?

    private let benefits = PremiumBenefitCatalog.benefits
    private let premiumThemes = PremiumBenefitCatalog.premiumThemes
    private let purchaseOptions = ModiPlusPurchaseOption.options

    private var selectedOption: ModiPlusPurchaseOption {
        purchaseOptions.first { $0.id == selectedOptionID } ?? purchaseOptions[0]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                heroSection
                benefitsSection
                themePreviewSection
                pricingSection

                #if DEBUG
                developerSection
                #endif
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appScreenPadding()
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .appGroupedBackground()
        .navigationTitle("MODI+")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColor.Background.primary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            themeManager.clearPreviewTheme()
        }
        .task {
            await premiumManager.loadProducts()
        }
        .onDisappear {
            themeManager.clearPreviewTheme()
        }
        .alert("MODI+", isPresented: purchaseErrorIsPresented) {
            Button("확인") {
                premiumManager.clearPurchaseErrorMessage()
            }
        } message: {
            Text(premiumManager.purchaseErrorMessage ?? "")
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ctaSection
        }
        .fullScreenCover(isPresented: $isShowingLogin, onDismiss: {
            pendingActionAfterLogin = nil
        }) {
            LoginView {
                guard authManager.session.isLoggedIn else {
                    pendingActionAfterLogin = nil
                    isShowingLogin = false
                    return
                }

                let action = pendingActionAfterLogin
                pendingActionAfterLogin = nil
                isShowingLogin = false

                Task {
                    await performPremiumAction(action)
                }
            }
            .environment(authManager)
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

    // MARK: - Pricing

    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "MODI+ 시작하기")

            VStack(spacing: AppSpacing.sm) {
                ForEach(purchaseOptions) { option in
                    purchaseOptionCard(option)
                }
            }

            Text(premiumManager.products.isEmpty ? "상품 정보를 불러오는 중입니다. App Store Connect 등록 상태에 따라 표시까지 시간이 걸릴 수 있어요." : "표시된 가격은 App Store에 등록된 가격을 기준으로 적용됩니다.")
                .font(AppFont.caption2)
                .foregroundStyle(AppColor.Text.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func purchaseOptionCard(_ option: ModiPlusPurchaseOption) -> some View {
        let product = premiumManager.product(for: option.productID)
        let price = product?.displayPrice ?? option.fallbackPrice

        return Button {
            selectedOptionID = option.id
        } label: {
            HStack(alignment: .center, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    HStack(spacing: AppSpacing.xs) {
                        Text(option.title)
                            .font(AppFont.headline)
                            .foregroundStyle(AppColor.Text.primary)

                        if let badge = option.badge {
                            Text(badge)
                                .font(AppFont.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColor.Text.onButton)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, AppSpacing.xxs)
                                .background(AppColor.Accent.highlight, in: Capsule(style: .continuous))
                        }
                    }

                    Text(option.subtitle)
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                    if premiumManager.isLoadingProducts && product == nil {
                        ProgressView()
                            .tint(AppColor.Accent.highlight)
                    } else {
                        Text(price)
                            .font(AppFont.headline)
                            .foregroundStyle(AppColor.Text.primary)
                    }

                    Text(productStatusText(for: option, product: product))
                        .font(AppFont.caption2)
                        .foregroundStyle(AppColor.Text.tertiary)
                }

                Image(systemName: selectedOptionID == option.id ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(selectedOptionID == option.id ? AppColor.Accent.highlight : AppColor.Text.tertiary)
            }
            .padding(AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(AppColor.Surface.card)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(
                        selectedOptionID == option.id ? AppColor.Accent.highlight : AppColor.Border.default,
                        lineWidth: selectedOptionID == option.id ? 1.5 : 0.75
                    )
            }
            .opacity(product == nil && !premiumManager.isLoadingProducts ? 0.6 : 1)
        }
        .buttonStyle(.plain)
        .disabled(product == nil && !premiumManager.products.isEmpty)
        .accessibilityLabel("\(option.title), \(price), \(option.renewalText)")
    }

    private func productStatusText(for option: ModiPlusPurchaseOption, product: Product?) -> String {
        if product == nil && premiumManager.isLoadingProducts {
            return "불러오는 중"
        }

        if product == nil && (!premiumManager.products.isEmpty || !premiumManager.isLoadingProducts) {
            return "상품 없음"
        }

        return option.renewalText
    }

    // MARK: - Theme Preview

    private var themePreviewSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "프리미엄 테마 미리보기")

            Text("감성적인 분위기로 MODI를 나만의 공간으로 꾸며보세요.")
                .font(AppFont.footnote)
                .foregroundStyle(AppColor.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: AppSpacing.md) {
                ForEach(premiumThemes) { theme in
                    ThemePreviewCard(
                        highlight: theme,
                        isSelected: themeManager.previewTheme == theme.theme
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            themeManager.setPreviewTheme(theme.theme)
                        }
                    }
                }
            }
            .padding(.vertical, AppSpacing.xxs)
        }
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 0) {
            Divider()

            VStack(spacing: AppSpacing.sm) {
                Button {
                    handlePremiumAction(.purchase(selectedOption.productID))
                } label: {
                    ZStack {
                        Text(primaryButtonTitle)
                            .opacity(premiumManager.isPurchasing ? 0 : 1)

                        if premiumManager.isPurchasing {
                            ProgressView()
                                .tint(AppColor.Text.onButton)
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(premiumManager.isPurchasing || premiumManager.hasPremium || premiumManager.product(for: selectedOption.productID) == nil)

                Button("이전 구매 복원") {
                    handlePremiumAction(.restore)
                }
                .font(AppFont.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(AppColor.Accent.highlight)
                .disabled(premiumManager.isPurchasing)

                legalDisclosure
            }
            .appScreenPadding()
            .padding(.vertical, AppSpacing.md)
            .background(AppColor.Background.primary)
        }
    }

    private var legalDisclosure: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("구독은 Apple ID 계정으로 결제되며, 현재 구독 기간이 끝나기 최소 24시간 전에 해지하지 않으면 자동으로 갱신됩니다. 구독은 App Store 계정 설정에서 언제든지 관리하거나 해지할 수 있습니다.")
                .font(AppFont.caption2)
                .foregroundStyle(AppColor.Text.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: AppSpacing.sm) {
                Button("이용약관") {
                    openSupportURL("https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
                }

                Text("·")
                    .foregroundStyle(AppColor.Text.tertiary)

                Button("개인정보 처리방침") {
                    openSupportURL("https://20kyi.github.io/modi-support/privacy.html")
                }
            }
            .font(AppFont.caption2)
            .foregroundStyle(AppColor.Accent.highlight)
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

    private var purchaseErrorIsPresented: Binding<Bool> {
        Binding(
            get: { premiumManager.purchaseErrorMessage != nil },
            set: { if !$0 { premiumManager.clearPurchaseErrorMessage() } }
        )
    }

    private var primaryButtonTitle: String {
        if premiumManager.hasPremium {
            return "MODI+ 이용 중"
        }

        if authManager.session.isGuest {
            return "로그인하고 MODI+ 시작"
        }

        return "\(selectedOption.title) 시작하기"
    }

    private func handlePremiumAction(_ action: PendingPremiumAction) {
        guard authManager.session.isLoggedIn else {
            pendingActionAfterLogin = action
            isShowingLogin = true
            return
        }

        Task {
            await performPremiumAction(action)
        }
    }

    private func performPremiumAction(_ action: PendingPremiumAction?) async {
        guard let action else { return }

        switch action {
        case .purchase(let productID):
            await premiumManager.purchase(productID: productID)
        case .restore:
            await premiumManager.restorePurchases()
        }
    }

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(AppFont.title3)
            .foregroundStyle(AppColor.Text.primary)
    }

    private func openSupportURL(_ rawValue: String) {
        guard let url = URL(string: rawValue) else { return }
        openURL(url)
    }
}

// MARK: - PendingPremiumAction

private enum PendingPremiumAction {
    case purchase(String)
    case restore
}

// MARK: - ModiPlusPurchaseOption

private struct ModiPlusPurchaseOption: Identifiable {
    let id: String
    let productID: String
    let title: String
    let subtitle: String
    let fallbackPrice: String
    let renewalText: String
    let badge: String?

    static let recommendedID = PremiumManager.ProductID.annual

    static let options: [ModiPlusPurchaseOption] = [
        ModiPlusPurchaseOption(
            id: PremiumManager.ProductID.monthly,
            productID: PremiumManager.ProductID.monthly,
            title: "월간 MODI+",
            subtitle: "가볍게 시작하고 매월 이용해요",
            fallbackPrice: "₩3,900",
            renewalText: "매월 자동 갱신",
            badge: nil
        ),
        ModiPlusPurchaseOption(
            id: PremiumManager.ProductID.annual,
            productID: PremiumManager.ProductID.annual,
            title: "연간 MODI+",
            subtitle: "1년 동안 더 합리적으로 이용해요",
            fallbackPrice: "₩29,000",
            renewalText: "매년 자동 갱신",
            badge: "추천"
        ),
        ModiPlusPurchaseOption(
            id: PremiumManager.ProductID.lifetime,
            productID: PremiumManager.ProductID.lifetime,
            title: "평생 이용권",
            subtitle: "구독 없이 한 번만 결제해요",
            fallbackPrice: "₩59,000",
            renewalText: "1회 결제",
            badge: nil
        ),
    ]
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
