import StoreKit
import SwiftUI

enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@MainActor
@Observable
final class SettingsViewModel {
    var isDailyDiscoveryNotificationEnabled: Bool
    var notificationTime: Date
    var appearanceMode: AppAppearanceMode
    var isHapticFeedbackEnabled: Bool

    private let storage: UserDefaults
    private enum StorageKeys {
        static let dailyDiscoveryNotificationEnabled = "settings.notifications.dailyDiscoveryEnabled"
        static let notificationTime = "settings.notifications.time"
        static let appearanceMode = "settings.app.appearanceMode"
        static let hapticFeedbackEnabled = "settings.app.hapticFeedbackEnabled"
    }

    init(storage: UserDefaults = .standard) {
        self.storage = storage
        let storedMode = storage.string(forKey: StorageKeys.appearanceMode) ?? AppAppearanceMode.system.rawValue
        appearanceMode = AppAppearanceMode(rawValue: storedMode) ?? .system

        if storage.object(forKey: StorageKeys.dailyDiscoveryNotificationEnabled) == nil {
            isDailyDiscoveryNotificationEnabled = true
        } else {
            isDailyDiscoveryNotificationEnabled = storage.bool(forKey: StorageKeys.dailyDiscoveryNotificationEnabled)
        }

        if storage.object(forKey: StorageKeys.hapticFeedbackEnabled) == nil {
            isHapticFeedbackEnabled = true
        } else {
            isHapticFeedbackEnabled = storage.bool(forKey: StorageKeys.hapticFeedbackEnabled)
        }

        if let storedDate = storage.object(forKey: StorageKeys.notificationTime) as? Date {
            notificationTime = storedDate
        } else {
            notificationTime = Self.defaultNotificationTime()
        }
    }

    func setDailyDiscoveryNotificationEnabled(_ isEnabled: Bool) {
        isDailyDiscoveryNotificationEnabled = isEnabled
        storage.set(isEnabled, forKey: StorageKeys.dailyDiscoveryNotificationEnabled)
    }

    func setNotificationTime(_ date: Date) {
        notificationTime = date
        storage.set(date, forKey: StorageKeys.notificationTime)
    }

    func setAppearanceMode(_ mode: AppAppearanceMode) {
        appearanceMode = mode
        storage.set(mode.rawValue, forKey: StorageKeys.appearanceMode)
    }

    func setHapticFeedbackEnabled(_ isEnabled: Bool) {
        isHapticFeedbackEnabled = isEnabled
        storage.set(isEnabled, forKey: StorageKeys.hapticFeedbackEnabled)
    }

    private static func defaultNotificationTime() -> Date {
        Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now) ?? .now
    }
}

struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview

    @State private var viewModel = SettingsViewModel()
    @State private var isSigningIn = false
    @State private var signInErrorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                accountSection
                notificationSection
                appSection
                supportSection
                infoSection
                accountManagementSection
            }
            .appScreenPadding()
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .appGroupedBackground()
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var accountSection: some View {
        settingsSection(title: "계정") {
            VStack(spacing: 0) {
                if authManager.session.isLoggedIn {
                    settingsValueRow(
                        icon: "person.fill",
                        title: authManager.session.nickname ?? "MODI Explorer",
                        subtitle: "Apple로 로그인됨"
                    )
                } else {
                    settingsValueRow(
                        icon: "person.crop.circle.badge.questionmark",
                        title: "게스트로 이용 중",
                        subtitle: "로그인하면 기록을 안전하게 보관할 수 있어요"
                    )
                    dividerInset()
                    appleSignInRow(title: "Apple로 로그인")
                }
            }
            .appCardStyle(padding: 0)
        }
    }

    private var notificationSection: some View {
        settingsSection(title: "알림") {
            VStack(spacing: 0) {
                settingsToggleRow(
                    icon: "bell.fill",
                    title: "오늘의 발견 알림",
                    isOn: Binding(
                        get: { viewModel.isDailyDiscoveryNotificationEnabled },
                        set: { viewModel.setDailyDiscoveryNotificationEnabled($0) }
                    )
                )
                dividerInset()
                settingsDatePickerRow(
                    icon: "clock.fill",
                    title: "알림 시간 변경",
                    selection: Binding(
                        get: { viewModel.notificationTime },
                        set: { viewModel.setNotificationTime($0) }
                    )
                )
            }
            .appCardStyle(padding: 0)
        }
    }

    private var appSection: some View {
        settingsSection(title: "앱") {
            VStack(spacing: 0) {
                settingsPickerRow(
                    icon: "circle.lefthalf.filled",
                    title: "다크모드",
                    selection: Binding(
                        get: { viewModel.appearanceMode },
                        set: { viewModel.setAppearanceMode($0) }
                    )
                )
                dividerInset()
                settingsToggleRow(
                    icon: "iphone.radiowaves.left.and.right",
                    title: "햅틱 피드백",
                    isOn: Binding(
                        get: { viewModel.isHapticFeedbackEnabled },
                        set: { viewModel.setHapticFeedbackEnabled($0) }
                    )
                )
            }
            .appCardStyle(padding: 0)
        }
    }

    private var supportSection: some View {
        settingsSection(title: "지원") {
            VStack(spacing: 0) {
                settingsLinkRow(icon: "questionmark.circle", title: "FAQ") {
                    openSupportURL("https://example.com/modi/faq")
                }
                dividerInset()
                settingsLinkRow(icon: "envelope", title: "문의하기") {
                    openSupportURL("mailto:support@modi.app")
                }
                dividerInset()
                settingsLinkRow(icon: "star.bubble", title: "앱 평가하기") {
                    requestReview()
                }
                dividerInset()
                settingsLinkRow(icon: "lock.doc", title: "개인정보 처리방침") {
                    openSupportURL("https://example.com/modi/privacy")
                }
                dividerInset()
                settingsLinkRow(icon: "doc.text", title: "이용약관") {
                    openSupportURL("https://example.com/modi/terms")
                }
            }
            .appCardStyle(padding: 0)
        }
    }

    private var infoSection: some View {
        settingsSection(title: "정보") {
            settingsValueRow(
                icon: "info.circle",
                title: "Version \(appVersion)",
                subtitle: nil
            )
        }
    }

    private var accountManagementSection: some View {
        settingsSection(title: "계정 관리") {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if let signInErrorMessage {
                    Text(signInErrorMessage)
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Semantic.error)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if authManager.session.isLoggedIn {
                    Button("로그아웃") {
                        authManager.setGuest()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button {
                        signInWithApple()
                    } label: {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)

                            Text("Apple로 로그인")
                                .font(AppFont.headline)
                                .foregroundStyle(.white)

                            Spacer()

                            if isSigningIn {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .frame(height: AppSpacing.minTouchTarget)
                        .background(Color.black, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSigningIn)
                }
            }
            .appCardStyle()
        }
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(title)
                .font(AppFont.title3)
                .foregroundStyle(AppColor.Text.primary)
            content()
        }
    }

    private func settingsValueRow(icon: String, title: String, subtitle: String?) -> some View {
        HStack(spacing: AppSpacing.md) {
            rowIcon(icon)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.Text.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .frame(minHeight: AppSpacing.minTouchTarget)
        .background(AppColor.Surface.card)
    }

    private func settingsToggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: AppSpacing.md) {
            rowIcon(icon)

            Text(title)
                .font(AppFont.body)
                .foregroundStyle(AppColor.Text.primary)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppColor.Accent.primary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .frame(minHeight: AppSpacing.minTouchTarget)
        .background(AppColor.Surface.card)
    }

    private func settingsDatePickerRow(icon: String, title: String, selection: Binding<Date>) -> some View {
        DatePicker(selection: selection, displayedComponents: .hourAndMinute) {
            HStack(spacing: AppSpacing.md) {
                rowIcon(icon)

                Text(title)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.Text.primary)
            }
        }
        .tint(AppColor.Accent.primary)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .frame(minHeight: AppSpacing.minTouchTarget)
        .background(AppColor.Surface.card)
    }

    private func settingsPickerRow(
        icon: String,
        title: String,
        selection: Binding<AppAppearanceMode>
    ) -> some View {
        HStack(spacing: AppSpacing.md) {
            rowIcon(icon)

            Text(title)
                .font(AppFont.body)
                .foregroundStyle(AppColor.Text.primary)

            Spacer()

            Picker("다크모드", selection: selection) {
                ForEach(AppAppearanceMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .tint(AppColor.Accent.primary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .frame(minHeight: AppSpacing.minTouchTarget)
        .background(AppColor.Surface.card)
    }

    private func settingsLinkRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                rowIcon(icon)

                Text(title)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.Text.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.Text.tertiary)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .frame(minHeight: AppSpacing.minTouchTarget)
            .background(AppColor.Surface.card)
        }
        .buttonStyle(.plain)
    }

    private func appleSignInRow(title: String) -> some View {
        Button {
            signInWithApple()
        } label: {
            HStack(spacing: AppSpacing.md) {
                rowIcon("apple.logo")

                Text(title)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.Text.primary)

                Spacer()

                if isSigningIn {
                    ProgressView()
                        .tint(AppColor.Accent.primary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColor.Text.tertiary)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .frame(minHeight: AppSpacing.minTouchTarget)
            .background(AppColor.Surface.card)
        }
        .buttonStyle(.plain)
        .disabled(isSigningIn)
    }

    private func rowIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(AppColor.Accent.primary)
            .frame(width: 28)
    }

    private func dividerInset() -> some View {
        Divider()
            .padding(.leading, AppSpacing.lg + AppSpacing.xl + AppSpacing.md)
            .background(AppColor.Surface.card)
    }

    private var appVersion: String {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return shortVersion
    }

    private func openSupportURL(_ rawValue: String) {
        guard let url = URL(string: rawValue) else { return }
        openURL(url)
    }

    private func signInWithApple() {
        isSigningIn = true
        signInErrorMessage = nil

        Task {
            do {
                _ = try await authManager.signInWithApple()
            } catch {
                signInErrorMessage = error.localizedDescription
            }
            isSigningIn = false
        }
    }
}

#Preview("로그인 사용자") {
    NavigationStack {
        SettingsView()
    }
    .environment(AuthManager.mock)
}

#Preview("게스트") {
    NavigationStack {
        SettingsView()
    }
    .environment(AuthManager(session: .guest))
}
