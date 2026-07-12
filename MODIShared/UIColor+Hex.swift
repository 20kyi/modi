import UIKit

extension UIColor {
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

    var relativeLuminance: CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return 0.5
        }

        func channel(_ value: CGFloat) -> CGFloat {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
    }

    func contrastingTextColor() -> UIColor {
        relativeLuminance > 0.55 ? UIColor(hex: "1C1C1E") : UIColor(hex: "FFFFFF")
    }
}
