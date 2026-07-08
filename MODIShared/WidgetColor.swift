import SwiftUI
import UIKit

enum WidgetColor {
    static func background(from themeColorHex: String, colorScheme: ColorScheme) -> Color {
        let lightUI = UIColor(hex: themeColorHex)
        let darkBaseUI = UIColor(hex: "111316")
        let darkUI = lightUI.blended(with: darkBaseUI, t: 0.62)
        let uiColor = colorScheme == .dark ? darkUI : lightUI
        return Color(uiColor: uiColor).opacity(colorScheme == .dark ? 0.38 : 0.48)
    }

    static let primaryText = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: "F4F4F5")
                : UIColor(hex: "1C1C1E")
        }
    )

    static let secondaryText = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: "A9AFB8")
                : UIColor(hex: "6E6E73")
        }
    )

    static let tertiaryText = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: "7E8792")
                : UIColor(hex: "AEAEB2")
        }
    )

    static let accent = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: "8EA0B3")
                : UIColor(hex: "5C6B7A")
        }
    )

    static let divider = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: "2A313B")
                : UIColor(hex: "ECECEF")
        }
    )
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
