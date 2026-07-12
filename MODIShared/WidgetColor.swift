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
