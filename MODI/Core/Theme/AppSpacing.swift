import SwiftUI

// MARK: - AppSpacing

/// Spacing scale based on a 4pt grid.
/// Generous whitespace for a calm, Pinterest-inspired layout.
enum AppSpacing {

    // MARK: Base Scale

    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let huge: CGFloat = 40
    static let massive: CGFloat = 48

    // MARK: Layout

    /// Horizontal screen edge inset.
    static let screenHorizontal: CGFloat = 20

    /// Vertical screen edge inset.
    static let screenVertical: CGFloat = 16

    /// Inner padding for cards and tiles.
    static let cardPadding: CGFloat = 16

    /// Gap between stacked sections.
    static let sectionGap: CGFloat = 32

    /// Gap between items within a section.
    static let itemGap: CGFloat = 12

    /// Grid gutter for photo masonry layouts.
    static let gridGutter: CGFloat = 8

    /// Minimum touch target per HIG (44pt).
    static let minTouchTarget: CGFloat = 44
}

// MARK: - EdgeInsets Presets

extension EdgeInsets {

    static let screen = EdgeInsets(
        top: AppSpacing.screenVertical,
        leading: AppSpacing.screenHorizontal,
        bottom: AppSpacing.screenVertical,
        trailing: AppSpacing.screenHorizontal
    )

    static let card = EdgeInsets(
        top: AppSpacing.cardPadding,
        leading: AppSpacing.cardPadding,
        bottom: AppSpacing.cardPadding,
        trailing: AppSpacing.cardPadding
    )
}
