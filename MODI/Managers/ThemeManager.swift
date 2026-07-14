import SwiftUI

// MARK: - ThemeManager

/// 앱 전역 UI 테마를 관리합니다.
@Observable
@MainActor
final class ThemeManager {

    static let shared = ThemeManager()

    private(set) var selectedTheme: AppTheme
    private(set) var previewTheme: AppTheme?

    private let storage: UserDefaults

    private enum StorageKeys {
        static let selectedTheme = "settings.app.selectedTheme"
        static let legacyAppearanceMode = "settings.app.appearanceMode"
    }

    var renderedTheme: AppTheme {
        previewTheme ?? selectedTheme
    }

    var currentTheme: Theme {
        renderedTheme.definition
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

    func setTheme(_ theme: AppTheme, isPremium: Bool = true) {
        guard selectedTheme != theme else { return }
        guard !theme.definition.isPremium || isPremium else { return }
        selectedTheme = theme
        storage.set(theme.rawValue, forKey: StorageKeys.selectedTheme)
    }

    func setPreviewTheme(_ theme: AppTheme) {
        previewTheme = theme
    }

    func clearPreviewTheme() {
        previewTheme = nil
    }

    /// 프리미엄이 해제된 경우 저장된 프리미엄 테마를 무료 테마로 되돌립니다.
    func resetToFreeThemeIfNeeded(isPremium: Bool) {
        guard !isPremium, selectedTheme.definition.isPremium else { return }
        let fallback: AppTheme = selectedTheme.definition.colors.isDark ? .dark : .light
        setTheme(fallback, isPremium: false)
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
