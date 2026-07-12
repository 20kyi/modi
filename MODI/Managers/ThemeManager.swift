import SwiftUI

// MARK: - ThemeManager

/// 앱 전역 UI 테마를 관리합니다.
@Observable
@MainActor
final class ThemeManager {

    static let shared = ThemeManager()

    private(set) var selectedTheme: AppTheme

    private let storage: UserDefaults

    private enum StorageKeys {
        static let selectedTheme = "settings.app.selectedTheme"
        static let legacyAppearanceMode = "settings.app.appearanceMode"
    }

    var currentTheme: Theme {
        selectedTheme.definition
    }

    var colors: ThemeColors {
        currentTheme.colors
    }

    var preferredColorScheme: ColorScheme {
        currentTheme.preferredColorScheme
    }

    init(storage: UserDefaults = .standard) {
        self.storage = storage

        if let storedRaw = storage.string(forKey: StorageKeys.selectedTheme),
           let storedTheme = AppTheme(rawValue: storedRaw) {
            selectedTheme = storedTheme
        } else {
            selectedTheme = Self.migrateLegacyAppearanceMode(storage: storage)
        }
    }

    func setTheme(_ theme: AppTheme) {
        guard selectedTheme != theme else { return }
        selectedTheme = theme
        storage.set(theme.rawValue, forKey: StorageKeys.selectedTheme)
    }

    private static func migrateLegacyAppearanceMode(storage: UserDefaults) -> AppTheme {
        guard let legacyRaw = storage.string(forKey: StorageKeys.legacyAppearanceMode) else {
            return .light
        }

        switch legacyRaw {
        case "dark":
            return .dark
        case "light", "system":
            return .light
        default:
            return .light
        }
    }
}
