import SwiftUI

// MARK: - AppRadius

/// Corner radius tokens for rounded, Pinterest-style surfaces.
enum AppRadius {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let photo: CGFloat = 14
    static let full: CGFloat = 999
}

// MARK: - AppShadow

/// Subtle elevation shadows — never heavy, always soft.
enum AppShadow {
    case subtle
    case medium
    case elevated

    var color: Color {
        switch self {
        case .subtle: AppColor.Shadow.subtle
        case .medium: AppColor.Shadow.medium
        case .elevated: AppColor.Shadow.strong
        }
    }

    var radius: CGFloat {
        switch self {
        case .subtle: 6
        case .medium: 12
        case .elevated: 20
        }
    }

    var yOffset: CGFloat {
        switch self {
        case .subtle: 2
        case .medium: 4
        case .elevated: 8
        }
    }
}

// MARK: - AppTheme

/// Central design system entry point.
/// Aggregates color, typography, spacing, radius, and shadow tokens.
enum AppTheme {

    static let color = AppColor.self
    static let font = AppFont.self
    static let spacing = AppSpacing.self
    static let radius = AppRadius.self
}

// MARK: - View Modifiers

extension View {

    /// Full-screen white background.
    func appScreenBackground() -> some View {
        background(AppColor.Background.primary)
            .scrollContentBackground(.hidden)
    }

    /// Soft grouped background for list-style screens.
    func appGroupedBackground() -> some View {
        background(AppColor.Background.grouped)
            .scrollContentBackground(.hidden)
    }

    /// Pinterest-style card with rounded corners and subtle shadow.
    func appCardStyle(
        radius: CGFloat = AppRadius.lg,
        shadow: AppShadow = .subtle,
        padding: CGFloat = AppSpacing.cardPadding
    ) -> some View {
        self
            .padding(padding)
            .background(AppColor.Surface.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(AppColor.Border.default, lineWidth: 0.75)
            }
            .shadow(color: shadow.color, radius: shadow.radius, x: 0, y: shadow.yOffset)
    }

    /// Photo tile style — rounded corners without shadow.
    func appPhotoStyle(radius: CGFloat = AppRadius.photo) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// Applies a design-system shadow without altering the view shape.
    func appShadow(_ shadow: AppShadow = .subtle) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: 0, y: shadow.yOffset)
    }

    /// Standard horizontal screen padding.
    func appScreenPadding() -> some View {
        padding(.horizontal, AppSpacing.screenHorizontal)
    }

    /// Full-width settings row with a comfortable tap target.
    func settingsRowStyle(alignment: Alignment = .leading) -> some View {
        self
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: alignment)
            .frame(minHeight: AppSpacing.settingsRowHeight)
            .contentShape(Rectangle())
    }

    /// Hairline divider color.
    func appDivider() -> some View {
        overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColor.Border.subtle)
                .frame(height: 0.5)
        }
    }
}

// MARK: - ShapeStyle Helpers

extension ShapeStyle where Self == Color {
    static var appBackground: Color { AppColor.Background.primary }
    static var appGroupedBackground: Color { AppColor.Background.grouped }
    static var appAccent: Color { AppColor.Accent.primary }
    static var appTextPrimary: Color { AppColor.Text.primary }
    static var appTextSecondary: Color { AppColor.Text.secondary }
}
