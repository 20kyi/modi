import SwiftUI
import UIKit

// MARK: - AppColor

/// MODI color palette — calm, minimal, photo-first.
/// Soft grays on white, inspired by Apple Photos and Pinterest.
enum AppColor {

    private static func dynamic(light: String, dark: String, lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) -> Color {
        Color(
            uiColor: UIColor { trait in
                if trait.userInterfaceStyle == .dark {
                    return UIColor(hex: dark, alpha: darkAlpha)
                }
                return UIColor(hex: light, alpha: lightAlpha)
            }
        )
    }

    /// Theme color 기반 이모지 배경(컬렉션 카드)을 다크모드에서 더 차분하게 보정합니다.
    /// - Light: 원본 테마 컬러
    /// - Dark: 테마 컬러를 다크 배경과 블렌딩해 채도/명도를 낮춤
    static func emojiBackground(from themeColorHex: String) -> Color {
        let lightUI = UIColor(hex: themeColorHex)
        let darkBaseUI = UIColor(hex: "111316") // AppColor.Background.primary dark hex
        let darkUI = lightUI.blended(with: darkBaseUI, t: 0.62)

        return Color(
            uiColor: UIColor { trait in
                trait.userInterfaceStyle == .dark ? darkUI : lightUI
            }
        )
    }

    // MARK: Background

    enum Background {
        /// Primary canvas — clean warm light / calm dark.
        static let primary = AppColor.dynamic(light: "FAF9F7", dark: "111316")

        /// Secondary surfaces — soft warm gray.
        static let secondary = AppColor.dynamic(light: "F3F2F0", dark: "191C20")

        /// Tertiary fill — subtle elevation layer.
        static let tertiary = AppColor.dynamic(light: "ECEBE8", dark: "23272D")

        /// Grouped content background.
        static let grouped = AppColor.dynamic(light: "F4F3F1", dark: "15181C")
    }

    // MARK: Surface

    enum Surface {
        /// Card and tile surfaces.
        static let card = AppColor.dynamic(light: "FFFFFF", dark: "1C2026")

        /// Elevated overlay — sheets, popovers.
        static let elevated = AppColor.dynamic(light: "FFFFFF", dark: "242A32")

        /// Muted surface for inactive states.
        static let muted = AppColor.dynamic(light: "ECECEE", dark: "2B3038")

        /// Dedicated dark surface for camera and immersive media.
        static let cameraBackdrop = AppColor.dynamic(light: "16191E", dark: "0E1014")
    }

    // MARK: Text

    enum Text {
        /// Primary body and headings.
        static let primary = AppColor.dynamic(light: "1C1C1E", dark: "F4F4F5")

        /// Secondary labels and metadata.
        static let secondary = AppColor.dynamic(light: "6E6E73", dark: "A9AFB8")

        /// Tertiary hints and placeholders.
        static let tertiary = AppColor.dynamic(light: "AEAEB2", dark: "7E8792")

        /// Disabled and de-emphasized text.
        static let quaternary = AppColor.dynamic(light: "C7C7CC", dark: "646D78")

        /// Text on accent-colored backgrounds.
        static let onAccent = Color(hex: "FFFFFF")
    }

    // MARK: Accent

    enum Accent {
        /// Primary brand accent — muted slate.
        static let primary = AppColor.dynamic(light: "5C6B7A", dark: "8EA0B3")

        /// Lighter accent for backgrounds and chips.
        static let soft = AppColor.dynamic(light: "E8ECF0", dark: "2C3440")

        /// Pressed / active accent state.
        static let pressed = AppColor.dynamic(light: "4A5764", dark: "A8B7C8")
    }

    // MARK: Border

    enum Border {
        /// Standard dividers and outlines.
        static let `default` = AppColor.dynamic(light: "DEDEE3", dark: "313844")

        /// Subtle separators between grouped items.
        static let subtle = AppColor.dynamic(light: "ECECEF", dark: "2A313B")

        /// Emphasized borders for focus rings.
        static let strong = AppColor.dynamic(light: "C9C9CF", dark: "475161")
    }

    // MARK: Shadow

    enum Shadow {
        static let subtle = AppColor.dynamic(light: "000000", dark: "000000", lightAlpha: 0.06, darkAlpha: 0.28)
        static let medium = AppColor.dynamic(light: "000000", dark: "000000", lightAlpha: 0.10, darkAlpha: 0.34)
        static let strong = AppColor.dynamic(light: "000000", dark: "000000", lightAlpha: 0.14, darkAlpha: 0.40)
    }

    // MARK: Semantic

    enum Semantic {
        static let success = AppColor.dynamic(light: "34C759", dark: "3DDC84")
        static let warning = AppColor.dynamic(light: "FF9F0A", dark: "FFB340")
        static let error = AppColor.dynamic(light: "FF3B30", dark: "FF6961")
    }

    // MARK: Overlay

    enum Overlay {
        static let scrim = AppColor.dynamic(light: "000000", dark: "000000", lightAlpha: 0.40, darkAlpha: 0.52)
        static let shimmer = AppColor.dynamic(light: "FFFFFF", dark: "FFFFFF", lightAlpha: 0.60, darkAlpha: 0.22)
    }

    // MARK: Semantic Roles

    enum Role {
        static let background = AppColor.Background.primary
        static let secondaryBackground = AppColor.Background.secondary
        static let surface = AppColor.Surface.card
        static let primaryText = AppColor.Text.primary
        static let secondaryText = AppColor.Text.secondary
        static let tertiaryText = AppColor.Text.tertiary
        static let accent = AppColor.Accent.primary
        static let border = AppColor.Border.default
        static let divider = AppColor.Border.subtle
        static let success = AppColor.Semantic.success
        static let warning = AppColor.Semantic.warning
        static let error = AppColor.Semantic.error
    }
}

// MARK: - Color + Hex

extension Color {

    /// Creates a color from a 6-digit hex string (e.g. `"F7F7F8"`).
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        self.init(red: red, green: green, blue: blue)
    }
}

private extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    func blended(with other: UIColor, t: CGFloat) -> UIColor {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0

        guard
            self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1),
            other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        else {
            return self
        }

        let clampedT = min(max(t, 0), 1)
        return UIColor(
            red: r1 * (1 - clampedT) + r2 * clampedT,
            green: g1 * (1 - clampedT) + g2 * clampedT,
            blue: b1 * (1 - clampedT) + b2 * clampedT,
            alpha: a1 * (1 - clampedT) + a2 * clampedT
        )
    }
}
