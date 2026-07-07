import SwiftUI

// MARK: - AppColor

/// MODI color palette — calm, minimal, photo-first.
/// Soft grays on white, inspired by Apple Photos and Pinterest.
enum AppColor {

    // MARK: Background

    enum Background {
        /// Primary canvas — clean white.
        static let primary = Color(hex: "FFFFFF")

        /// Secondary surfaces — soft warm gray.
        static let secondary = Color(hex: "F7F7F8")

        /// Tertiary fill — subtle elevation layer.
        static let tertiary = Color(hex: "F0F0F2")

        /// Grouped content background.
        static let grouped = Color(hex: "F5F5F7")
    }

    // MARK: Surface

    enum Surface {
        /// Card and tile surfaces.
        static let card = Color(hex: "FFFFFF")

        /// Elevated overlay — sheets, popovers.
        static let elevated = Color(hex: "FFFFFF")

        /// Muted surface for inactive states.
        static let muted = Color(hex: "ECECEE")
    }

    // MARK: Text

    enum Text {
        /// Primary body and headings.
        static let primary = Color(hex: "1C1C1E")

        /// Secondary labels and metadata.
        static let secondary = Color(hex: "6E6E73")

        /// Tertiary hints and placeholders.
        static let tertiary = Color(hex: "AEAEB2")

        /// Disabled and de-emphasized text.
        static let quaternary = Color(hex: "C7C7CC")

        /// Text on accent-colored backgrounds.
        static let onAccent = Color(hex: "FFFFFF")
    }

    // MARK: Accent

    enum Accent {
        /// Primary brand accent — muted slate.
        static let primary = Color(hex: "5C6B7A")

        /// Lighter accent for backgrounds and chips.
        static let soft = Color(hex: "E8ECF0")

        /// Pressed / active accent state.
        static let pressed = Color(hex: "4A5764")
    }

    // MARK: Border

    enum Border {
        /// Standard dividers and outlines.
        static let `default` = Color(hex: "E5E5EA")

        /// Subtle separators between grouped items.
        static let subtle = Color(hex: "F0F0F2")

        /// Emphasized borders for focus rings.
        static let strong = Color(hex: "D1D1D6")
    }

    // MARK: Shadow

    enum Shadow {
        static let subtle = Color.black.opacity(0.04)
        static let medium = Color.black.opacity(0.08)
        static let strong = Color.black.opacity(0.12)
    }

    // MARK: Semantic

    enum Semantic {
        static let success = Color(hex: "34C759")
        static let warning = Color(hex: "FF9F0A")
        static let error = Color(hex: "FF3B30")
    }

    // MARK: Overlay

    enum Overlay {
        static let scrim = Color.black.opacity(0.40)
        static let shimmer = Color.white.opacity(0.60)
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
