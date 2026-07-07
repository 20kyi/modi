import SwiftUI

// MARK: - AppFont

/// Typography scale aligned with Apple's Human Interface Guidelines.
/// Uses SF Pro with restrained weights for a calm, editorial feel.
enum AppFont {

    // MARK: Display

    /// Hero titles — splash, onboarding headlines.
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)

    /// Section titles — month headers, feature intros.
    static let title1 = Font.system(size: 28, weight: .bold, design: .default)

    /// Card titles — photo themes, day labels.
    static let title2 = Font.system(size: 22, weight: .semibold, design: .default)

    /// Subsection titles.
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)

    // MARK: Body

    /// Emphasized inline labels and button text.
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)

    /// Primary reading text.
    static let body = Font.system(size: 17, weight: .regular, design: .default)

    /// Secondary descriptive text.
    static let callout = Font.system(size: 16, weight: .regular, design: .default)

    /// Supporting labels beneath titles.
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)

    // MARK: Caption

    /// Timestamps, metadata, badge text.
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)

    /// Small labels and overlines.
    static let caption1 = Font.system(size: 12, weight: .regular, design: .default)

    /// Smallest annotation text.
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: Rounded Variant

    /// Friendly rounded style for onboarding and celebratory moments.
    enum Rounded {
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    }
}

// MARK: - View Modifier

extension View {

    func appFont(_ font: Font, color: Color = AppColor.Text.primary) -> some View {
        self
            .font(font)
            .foregroundStyle(color)
    }
}
