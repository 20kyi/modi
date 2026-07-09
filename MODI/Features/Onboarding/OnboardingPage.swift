import SwiftUI

// MARK: - Page Model

enum OnboardingVisual {
    case textOnly
    case heroImage
    case photoGrid
}

struct OnboardingPageData: Identifiable, Equatable {
    let id: Int
    let title: String
    let subtitle: String
    let visual: OnboardingVisual
}

// MARK: - Page Content

struct OnboardingPageContent: View {
    let page: OnboardingPageData
    let isActive: Bool

    var body: some View {
        VStack(spacing: 0) {
            visualSection
                .frame(maxWidth: .infinity)
                .padding(.bottom, AppSpacing.xxl)

            textSection
        }
        .appScreenPadding()
        .opacity(isActive ? 1 : 0.6)
        .scaleEffect(isActive ? 1 : 0.97)
        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: isActive)
    }

    @ViewBuilder
    private var visualSection: some View {
        switch page.visual {
        case .textOnly:
            OnboardingTextOnlyVisual()
        case .heroImage:
            OnboardingHeroPlaceholder()
        case .photoGrid:
            OnboardingPhotoGridPlaceholder()
        }
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text(page.title)
                .font(AppFont.largeTitle)
                .foregroundStyle(AppColor.Text.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Text(page.subtitle)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.Text.secondary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Visual Placeholders

struct OnboardingTextOnlyVisual: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColor.Accent.soft,
                            AppColor.Background.secondary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 220)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(AppColor.Accent.primary.opacity(0.55))
                }
                .appPhotoStyle(radius: AppRadius.xxl)
                .appShadow(.medium)
        }
        .padding(.top, AppSpacing.huge)
    }
}

struct OnboardingHeroPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: "D4E4F7"),
                        Color(hex: "A8C8E8"),
                        Color(hex: "7BA3D4")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 300)
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 72, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.45))
                    .offset(x: -28, y: -32)
            }
            .overlay(alignment: .topLeading) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.white.opacity(0.7))
                    .offset(x: 28, y: 28)
            }
            .appPhotoStyle(radius: AppRadius.xxl)
            .appShadow(.elevated)
            .padding(.top, AppSpacing.xl)
    }
}

struct OnboardingPhotoGridPlaceholder: View {
    private let tiles: [CGFloat] = [1.25, 1.6, 1.05, 1.45]
    private let tileColors: [Color] = [
        Color(hex: "F0E8E0"),
        Color(hex: "DDE8F0"),
        Color(hex: "F5E0E8"),
        Color(hex: "E0E8E4")
    ]

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.gridGutter),
        GridItem(.flexible(), spacing: AppSpacing.gridGutter)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.gridGutter) {
            ForEach(tiles.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                    .fill(tileColors[index])
                    .aspectRatio(tiles[index], contentMode: .fit)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(AppColor.Text.quaternary)
                    }
                    .appShadow(.subtle)
            }
        }
        .padding(.top, AppSpacing.lg)
    }
}

// MARK: - Page Indicator

struct OnboardingPageIndicator: View {
    let pageCount: Int
    let currentIndex: Int

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? AppColor.Text.primary : AppColor.Text.quaternary)
                    .frame(width: index == currentIndex ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: currentIndex)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("페이지 \(currentIndex + 1) / \(pageCount)")
    }
}

// MARK: - Primary Button

struct OnboardingPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.headline)
                .foregroundStyle(AppColor.Text.onAccent)
                .frame(maxWidth: .infinity)
                .frame(height: AppSpacing.minTouchTarget + AppSpacing.sm)
                .background(AppColor.Accent.primary, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        }
        .buttonStyle(OnboardingButtonStyle())
    }
}

private struct OnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Page Content") {
    OnboardingPageContent(
        page: OnboardingPageData(
            id: 0,
            title: "세상은\n생각보다\n다채롭습니다.",
            subtitle: "평범한 하루도 시선을 바꾸면 새로운 컬렉션이 됩니다.",
            visual: .textOnly
        ),
        isActive: true
    )
    .appScreenBackground()
}
