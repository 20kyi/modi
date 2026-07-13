import SwiftUI
import UIKit

// MARK: - AppColor

/// MODI color palette — ThemeManager 기반 중앙 색상 시스템.
enum AppColor {

    private static var palette: ThemeColors {
        ThemeManager.shared.colors
    }

    /// Theme color 기반 이모지 배경(컬렉션 카드)을 다크 테마에서 더 차분하게 보정합니다.
    static func emojiBackground(from themeColorHex: String) -> Color {
        let lightUI = UIColor(hex: themeColorHex)

        guard palette.isDark else {
            return Color(hex: themeColorHex)
        }

        let darkBaseUI = UIColor(hex: palette.backgroundHex)
        let darkUI = lightUI.blended(with: darkBaseUI, t: 0.62)
        return Color(uiColor: darkUI)
    }

    // MARK: Background

    enum Background {
        static var primary: Color { palette.background }
        static var secondary: Color { palette.backgroundSecondary }
        static var tertiary: Color { palette.backgroundTertiary }
        static var grouped: Color { palette.backgroundGrouped }
    }

    // MARK: Surface

    enum Surface {
        static var card: Color { palette.surface }
        static var elevated: Color { palette.surfaceElevated }
        static var muted: Color { palette.surfaceMuted }
        static var cameraBackdrop: Color {
            palette.isDark
                ? Color(hex: "0E1014")
                : Color(hex: "16191E")
        }
    }

    // MARK: Text

    enum Text {
        static var primary: Color { palette.text }
        static var secondary: Color { palette.subText }
        static var tertiary: Color { palette.textTertiary }
        static var quaternary: Color { palette.textQuaternary }
        static var onAccent: Color { palette.onAccent }
        /// 채움형 버튼 라벨 — Midnight Film은 골드 배경 대비색
        static var onButton: Color {
            ThemeManager.shared.selectedTheme == .midnightFilm
                ? palette.onHighlight
                : palette.onAccent
        }
    }

    // MARK: Accent
    //
    // ThemeColors.primary  → Accent.primary   (주요 버튼·채움 UI)
    // ThemeColors.accent   → Accent.highlight  (탭·토글·인디케이터·링크 등 포인트 컬러)

    enum Accent {
        static var primary: Color { palette.primary }
        static var soft: Color { palette.accentSoft }
        static var pressed: Color { palette.accentPressed }
        /// ThemeColors.accent — 테마별 포인트 컬러 (예: Midnight Film 골드)
        static var highlight: Color { palette.accent }

        // MARK: Button

        /// 채움형 주요 버튼 배경
        static var buttonFill: Color {
            ThemeManager.shared.selectedTheme == .midnightFilm
                ? palette.accent
                : palette.primary
        }

        /// 채움형 주요 버튼 pressed 상태
        static var buttonPressed: Color {
            if ThemeManager.shared.selectedTheme == .midnightFilm {
                return palette.accentButtonPressed
            }
            return palette.accentPressed
        }

        /// 보조 버튼 배경·soft fill
        static var buttonSoft: Color {
            if ThemeManager.shared.selectedTheme == .midnightFilm {
                return palette.accentButtonSoft
            }
            return palette.accentSoft
        }

        /// 보조·텍스트 버튼 라벨, borderedProminent tint
        static var buttonLabel: Color { palette.accent }

        /// Empty state 등 텍스트 액션 버튼 라벨
        static var textAction: Color {
            ThemeManager.shared.selectedTheme == .midnightFilm
                ? palette.primary
                : palette.accent
        }
    }

    // MARK: Border

    enum Border {
        static var `default`: Color { palette.borderDefault }
        static var subtle: Color { palette.borderSubtle }
        static var strong: Color { palette.borderStrong }
    }

    // MARK: Shadow

    enum Shadow {
        static var subtle: Color { palette.shadowSubtle }
        static var medium: Color { palette.shadowMedium }
        static var strong: Color { palette.shadowStrong }
    }

    // MARK: Semantic

    enum Semantic {
        static let success = Color(hex: "34C759")
        static let warning = Color(hex: "FF9F0A")
        static let error = Color(hex: "FF3B30")

        static var successThemed: Color {
            palette.isDark ? Color(hex: "3DDC84") : Color(hex: "34C759")
        }

        static var warningThemed: Color {
            palette.isDark ? Color(hex: "FFB340") : Color(hex: "FF9F0A")
        }

        static var errorThemed: Color {
            palette.isDark ? Color(hex: "FF6961") : Color(hex: "FF3B30")
        }
    }

    // MARK: Overlay

    enum Overlay {
        static var scrim: Color { palette.overlayScrim }
        static var shimmer: Color { palette.overlayShimmer }
    }

    // MARK: Theme Palette

    /// 미션·컬렉션 테마 컬러에서 버튼·완료 상태용 accent를 파생합니다.
    struct ThemePalette {
        let accent: Color
        let pressed: Color
        let softFill: Color
        let completedForeground: Color
        let onAccent: Color
    }

    static func themePalette(from themeColorHex: String) -> ThemePalette {
        let lightBase = UIColor(hex: themeColorHex)
        let darkBase = lightBase.blended(with: UIColor(hex: palette.backgroundHex), t: 0.62)

        let lightAccent = lightBase.blended(with: UIColor(hex: "2E3842"), t: 0.48)
        let lightPressed = lightBase.blended(with: UIColor(hex: "1C2228"), t: 0.58)
        let darkAccent = darkBase.blended(with: UIColor(hex: "C8D4E0"), t: 0.30)
        let darkPressed = darkBase.blended(with: UIColor(hex: "DCE4EC"), t: 0.20)

        let accentUIColor = palette.isDark ? darkAccent : lightAccent
        let pressedUIColor = palette.isDark ? darkPressed : lightPressed
        let baseUIColor = palette.isDark ? darkBase : lightBase

        return ThemePalette(
            accent: Color(uiColor: accentUIColor),
            pressed: Color(uiColor: pressedUIColor),
            softFill: Color(
                uiColor: baseUIColor.withAlphaComponent(palette.isDark ? 0.42 : 0.55)
            ),
            completedForeground: Color(uiColor: accentUIColor),
            onAccent: Color(uiColor: accentUIColor.contrastingTextColor())
        )
    }

    // MARK: Semantic Roles

    enum Role {
        static var background: Color { AppColor.Background.primary }
        static var secondaryBackground: Color { AppColor.Background.secondary }
        static var surface: Color { AppColor.Surface.card }
        static var primaryText: Color { AppColor.Text.primary }
        static var secondaryText: Color { AppColor.Text.secondary }
        static var tertiaryText: Color { AppColor.Text.tertiary }
        static var accent: Color { AppColor.Accent.highlight }
        static var border: Color { AppColor.Border.default }
        static var divider: Color { AppColor.Border.subtle }
        static var success: Color { AppColor.Semantic.successThemed }
        static var warning: Color { AppColor.Semantic.warningThemed }
        static var error: Color { AppColor.Semantic.errorThemed }
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
