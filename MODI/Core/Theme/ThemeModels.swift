import SwiftUI
import UIKit

// MARK: - AppTheme

/// 앱 전체 UI 테마 식별자.
enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case pastelDiary
    case midnightFilm
    case natureArchive

    var id: String { rawValue }

    var definition: Theme {
        switch self {
        case .light:
            Theme(
                id: rawValue,
                name: "Light",
                emoji: "☀️",
                colors: ThemeColors(
                    background: "FAF9F7",
                    surface: "FFFFFF",
                    primary: "5C6B7A",
                    secondary: "E8ECF0",
                    accent: "4A5764",
                    text: "1C1C1E",
                    subText: "6E6E73",
                    isDark: false
                ),
                isPremium: false
            )
        case .dark:
            Theme(
                id: rawValue,
                name: "Dark",
                emoji: "🌙",
                colors: ThemeColors(
                    background: "111316",
                    surface: "1C2026",
                    primary: "8EA0B3",
                    secondary: "2C3440",
                    accent: "A8B7C8",
                    text: "F4F4F5",
                    subText: "A9AFB8",
                    isDark: true
                ),
                isPremium: false
            )
        case .pastelDiary:
            Theme(
                id: rawValue,
                name: "Pastel Diary",
                emoji: "🌸",
                colors: ThemeColors(
                    background: "FFF7FA",
                    surface: "FFFFFF",
                    primary: "E8A7B8",
                    secondary: "A8C7E8",
                    accent: "F4D58D",
                    text: "3D3D3D",
                    subText: "8A8A8A",
                    isDark: false
                ),
                isPremium: true
            )
        case .midnightFilm:
            Theme(
                id: rawValue,
                name: "Midnight Film",
                emoji: "🌌",
                colors: ThemeColors(
                    background: "0F111A",
                    surface: "191D2B",
                    primary: "8B7CFF",
                    secondary: "4C536A",
                    accent: "E8C46A",
                    text: "F5F5F5",
                    subText: "A5A8B5",
                    isDark: true
                ),
                isPremium: true
            )
        case .natureArchive:
            Theme(
                id: rawValue,
                name: "Nature Archive",
                emoji: "🌱",
                colors: ThemeColors(
                    background: "F4F7F1",
                    surface: "FFFFFF",
                    primary: "8FAF8B",
                    secondary: "C8B89A",
                    accent: "4F6F52",
                    text: "30352F",
                    subText: "7A8278",
                    isDark: false
                ),
                isPremium: true
            )
        }
    }
}

// MARK: - ThemeColors

/// 테마별 핵심 색상 팔레트.
struct ThemeColors: Equatable {
    let background: Color
    let surface: Color
    let primary: Color
    let secondary: Color
    let accent: Color
    let text: Color
    let subText: Color
    let isDark: Bool

    init(
        background: String,
        surface: String,
        primary: String,
        secondary: String,
        accent: String,
        text: String,
        subText: String,
        isDark: Bool
    ) {
        self.background = Color(hex: background)
        self.surface = Color(hex: surface)
        self.primary = Color(hex: primary)
        self.secondary = Color(hex: secondary)
        self.accent = Color(hex: accent)
        self.text = Color(hex: text)
        self.subText = Color(hex: subText)
        self.isDark = isDark
    }

    var backgroundHex: String {
        background.hexString
    }

    // MARK: Derived Tokens

    var backgroundSecondary: Color {
        background.blended(with: secondary, amount: isDark ? 0.55 : 0.42)
    }

    var backgroundTertiary: Color {
        background.blended(with: secondary, amount: isDark ? 0.72 : 0.58)
    }

    var backgroundGrouped: Color {
        background.blended(with: secondary, amount: isDark ? 0.48 : 0.35)
    }

    var surfaceElevated: Color {
        surface.blended(with: primary, amount: isDark ? 0.18 : 0.06)
    }

    var surfaceMuted: Color {
        secondary.blended(with: background, amount: isDark ? 0.35 : 0.45)
    }

    var textTertiary: Color {
        subText.blended(with: background, amount: 0.35)
    }

    var textQuaternary: Color {
        subText.blended(with: background, amount: 0.55)
    }

    var accentSoft: Color {
        let mixed = primary.blended(with: accent, amount: isDark ? 0.30 : 0.20)
        return mixed.blended(with: background, amount: isDark ? 0.70 : 0.80)
    }

    var accentPressed: Color {
        primary.blended(with: accent, amount: isDark ? 0.28 : 0.38)
    }

    var buttonSoftFill: Color {
        primary.blended(with: background, amount: isDark ? 0.72 : 0.82)
    }

    var buttonPressedFill: Color {
        primary.blended(with: background, amount: isDark ? 0.38 : 0.28)
    }

    var accentButtonPressed: Color {
        accent.blended(with: background, amount: isDark ? 0.32 : 0.22)
    }

    var accentButtonSoft: Color {
        accent.blended(with: background, amount: isDark ? 0.68 : 0.78)
    }

    var borderDefault: Color {
        subText.blended(with: background, amount: isDark ? 0.62 : 0.72)
    }

    var borderSubtle: Color {
        subText.blended(with: background, amount: isDark ? 0.78 : 0.84)
    }

    var borderStrong: Color {
        subText.blended(with: text, amount: isDark ? 0.45 : 0.55)
    }

    var shadowSubtle: Color {
        Color.black.opacity(isDark ? 0.28 : 0.06)
    }

    var shadowMedium: Color {
        Color.black.opacity(isDark ? 0.34 : 0.10)
    }

    var shadowStrong: Color {
        Color.black.opacity(isDark ? 0.40 : 0.14)
    }

    var overlayScrim: Color {
        Color.black.opacity(isDark ? 0.52 : 0.40)
    }

    var overlayShimmer: Color {
        Color.white.opacity(isDark ? 0.22 : 0.60)
    }

    var onAccent: Color {
        primary.contrastingTextColor
    }

    /// highlight(accent) 배경 위 전경색 — 예: Midnight Film 골드 버튼 라벨
    var onHighlight: Color {
        accent.contrastingTextColor
    }
}

// MARK: - Theme

/// 앱 UI 테마 정의. 추후 MODI+ Premium 잠금 처리를 위해 `isPremium`을 포함합니다.
struct Theme: Equatable, Identifiable {
    let id: String
    let name: String
    let emoji: String
    let colors: ThemeColors
    let isPremium: Bool

    var displayName: String {
        "\(emoji) \(name)"
    }

    var preferredColorScheme: ColorScheme {
        colors.isDark ? .dark : .light
    }
}

// MARK: - Color Helpers

private extension Color {
    func blended(with other: Color, amount: CGFloat) -> Color {
        let uiSelf = UIColor(self)
        let uiOther = UIColor(other)
        return Color(uiColor: uiSelf.blended(with: uiOther, t: amount))
    }

    var contrastingTextColor: Color {
        Color(uiColor: UIColor(self).contrastingTextColor())
    }

    var hexString: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return "000000"
        }
        return String(
            format: "%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}
