import StoreKit
import SwiftData
import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    var isDailyDiscoveryNotificationEnabled: Bool
    var notificationTime: Date
    var isHapticFeedbackEnabled: Bool

    private let storage: UserDefaults
    private enum StorageKeys {
        static let dailyDiscoveryNotificationEnabled = "settings.notifications.dailyDiscoveryEnabled"
        static let notificationTime = "settings.notifications.time"
        static let hapticFeedbackEnabled = "settings.app.hapticFeedbackEnabled"
    }

    init(storage: UserDefaults = .standard) {
        self.storage = storage

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

    func setHapticFeedbackEnabled(_ isEnabled: Bool) {
        isHapticFeedbackEnabled = isEnabled
        storage.set(isEnabled, forKey: StorageKeys.hapticFeedbackEnabled)
        if isEnabled {
            HapticManager.shared.previewEnabledFeedback()
        }
    }

    private static func defaultNotificationTime() -> Date {
        Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now) ?? .now
    }
}

struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(MissionManager.self) private var missionManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var viewModel = SettingsViewModel()
    @State private var isSigningIn = false
    @State private var isDeletingAccount = false
    @State private var isUpdatingNickname = false
    @State private var nicknameDraft = ""
    @State private var signInErrorMessage: String?
    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                accountSection
                notificationSection
                appSection
                supportSection
                infoSection

                #if DEBUG
                developerSection
                #endif

                accountManagementSection
            }
            .appScreenPadding()
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .appGroupedBackground()
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColor.Background.primary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            syncNicknameDraftIfNeeded()
        }
        .onChange(of: authManager.session.nickname) {
            syncNicknameDraftIfNeeded()
        }
        .alert("로그아웃하시겠어요?", isPresented: $showSignOutConfirmation) {
            Button("취소", role: .cancel) {}
            Button("로그아웃", role: .destructive) {
                clearLocalUserData()
                authManager.signOut()
                hasCompletedOnboarding = false
            }
        }
        .alert("회원탈퇴하시겠어요?", isPresented: $showDeleteAccountConfirmation) {
            Button("취소", role: .cancel) {}
            Button("회원탈퇴", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("탈퇴 시 계정과 기록이 모두 삭제되며 복구할 수 없어요.")
        }
    }

    private var accountSection: some View {
        settingsSection(title: "계정") {
            VStack(spacing: 0) {
                if authManager.session.isLoggedIn {
                    settingsValueRow(
                        icon: "person.fill",
                        title: authManager.session.displayName,
                        subtitle: "Apple로 로그인됨"
                    )
                    dividerInset()
                    nicknameEditorRow
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

    private var nicknameEditorRow: some View {
        HStack(spacing: AppSpacing.sm) {
            rowIcon("pencil")

            TextField("닉네임 입력", text: $nicknameDraft)
                .font(AppFont.body)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            Button {
                updateNickname()
            } label: {
                if isUpdatingNickname {
                    ProgressView()
                        .tint(AppColor.Accent.highlight)
                        .frame(width: 22, height: 22)
                } else {
                    Text("저장")
                        .font(AppFont.footnote)
                        .fontWeight(.semibold)
                }
            }
            .disabled(!canUpdateNickname)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.lg)
        .frame(minHeight: AppSpacing.settingsRowHeight)
        .background(AppColor.Surface.card)
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
                NavigationLink {
                    ThemeSelectionView()
                } label: {
                    HStack(spacing: AppSpacing.md) {
                        rowIcon("paintpalette.fill")

                        Text("테마")
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.Text.primary)

                        Spacer(minLength: 0)

                        Text(themeManager.currentTheme.displayName)
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.Text.secondary)
                            .lineLimit(1)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColor.Text.tertiary)
                    }
                    .settingsRowStyle()
                    .background(AppColor.Surface.card)
                }
                .buttonStyle(.plain)
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

    #if DEBUG
    private var developerSection: some View {
        settingsSection(title: "개발자") {
            VStack(spacing: 0) {
                settingsToggleRow(
                    icon: "hammer.fill",
                    title: "프리미엄 상태",
                    subtitle: "개발·테스트용 프리미엄 시뮬레이션",
                    isOn: Binding(
                        get: { premiumManager.isDeveloperPremiumEnabled },
                        set: { premiumManager.setDeveloperPremiumEnabled($0) }
                    )
                )
            }
            .appCardStyle(padding: 0)
        }
    }
    #endif

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
                    VStack(spacing: AppSpacing.sm) {
                        Button("로그아웃") {
                            showSignOutConfirmation = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(isDeletingAccount)

                        Button {
                            showDeleteAccountConfirmation = true
                        } label: {
                            ZStack {
                                Text("회원탈퇴")
                                    .font(AppFont.headline)
                                    .frame(maxWidth: .infinity, alignment: .center)

                                HStack {
                                    Spacer()
                                    if isDeletingAccount {
                                        ProgressView()
                                            .tint(AppColor.Semantic.error)
                                    }
                                }
                            }
                            .foregroundStyle(AppColor.Semantic.error)
                            .padding(.horizontal, AppSpacing.lg)
                            .frame(height: AppSpacing.minTouchTarget)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                                    .stroke(AppColor.Semantic.error.opacity(0.4), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isDeletingAccount)
                    }
                } else {
                    Button {
                        signInWithApple()
                    } label: {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AppColor.Text.onAccent)

                            Text("Apple로 로그인")
                                .font(AppFont.headline)
                                .foregroundStyle(AppColor.Text.onAccent)

                            Spacer()

                            if isSigningIn {
                                ProgressView()
                                    .tint(AppColor.Text.onAccent)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .frame(height: AppSpacing.minTouchTarget)
                        .background(AppColor.Accent.primary, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSigningIn || isDeletingAccount)
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
        .settingsRowStyle()
        .background(AppColor.Surface.card)
    }

    private func settingsToggleRow(
        icon: String,
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>
    ) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
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

                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(AppColor.Accent.highlight)
                    .allowsHitTesting(false)
            }
            .settingsRowStyle()
            .background(AppColor.Surface.card)
        }
        .buttonStyle(.plain)
    }

    private func settingsDatePickerRow(icon: String, title: String, selection: Binding<Date>) -> some View {
        HStack(spacing: AppSpacing.md) {
            rowIcon(icon)

            Text(title)
                .font(AppFont.body)
                .foregroundStyle(AppColor.Text.primary)

            Spacer(minLength: 0)

            Text(formattedTime(selection.wrappedValue))
                .font(AppFont.body)
                .foregroundStyle(AppColor.Text.secondary)
        }
        .settingsRowStyle()
        .background(AppColor.Surface.card)
        .overlay {
            DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .opacity(0.02)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func settingsLinkRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                rowIcon(icon)

                Text(title)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.Text.primary)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.Text.tertiary)
            }
            .settingsRowStyle()
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

                Spacer(minLength: 0)

                if isSigningIn {
                    ProgressView()
                        .tint(AppColor.Accent.highlight)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColor.Text.tertiary)
                }
            }
            .settingsRowStyle()
            .background(AppColor.Surface.card)
        }
        .buttonStyle(.plain)
        .disabled(isSigningIn)
    }

    private func rowIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(AppColor.Accent.highlight)
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

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeStyle = .short
        return formatter.string(from: date)
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

    private var canUpdateNickname: Bool {
        let trimmed = nicknameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        return !isUpdatingNickname &&
            !trimmed.isEmpty &&
            trimmed != authManager.session.displayName
    }

    private func syncNicknameDraftIfNeeded() {
        guard authManager.session.isLoggedIn else { return }
        nicknameDraft = authManager.session.displayName
    }

    private func updateNickname() {
        let nickname = nicknameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nickname.isEmpty else { return }

        isUpdatingNickname = true
        signInErrorMessage = nil

        Task {
            defer { isUpdatingNickname = false }

            do {
                try await authManager.updateNickname(nickname)
                nicknameDraft = authManager.session.displayName
            } catch {
                signInErrorMessage = error.localizedDescription
            }
        }
    }

    private func deleteAccount() {
        HapticManager.shared.warning()

        isDeletingAccount = true
        signInErrorMessage = nil

        Task {
            do {
                try await authManager.deleteAccount()
                clearLocalUserData()
                hasCompletedOnboarding = false
            } catch {
                signInErrorMessage = error.localizedDescription
            }
            isDeletingAccount = false
        }
    }

    private func clearLocalUserData() {
        let repository = RecordRepository(modelContext: modelContext)
        let collectionRepository = CollectionRepository(modelContext: modelContext)

        repository.deleteAllRecords()
        collectionRepository.resetForSignedOutState()
        CollectionStore().resetForSignedOutState()
        missionManager.resetForSignedOutState()
        WidgetDataStore.clearAll()
    }
}

#Preview("로그인 사용자 · Light") {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [MODIRecord.self, MODICollection.self], inMemory: true)
    .environment(MissionManager.mock)
    .environment(AuthManager.mock)
    .environment(ThemeManager.shared)
    .environment(PremiumManager.shared)
    .preferredColorScheme(.light)
}

#Preview("로그인 사용자 · Dark") {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [MODIRecord.self, MODICollection.self], inMemory: true)
    .environment(MissionManager.mock)
    .environment(AuthManager.mock)
    .environment(ThemeManager.shared)
    .environment(PremiumManager.shared)
    .preferredColorScheme(.dark)
}

#Preview("게스트 · Light") {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [MODIRecord.self, MODICollection.self], inMemory: true)
    .environment(MissionManager.mock)
    .environment(AuthManager(session: .guest))
    .environment(ThemeManager.shared)
    .environment(PremiumManager.shared)
    .preferredColorScheme(.light)
}

#Preview("게스트 · Dark") {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [MODIRecord.self, MODICollection.self], inMemory: true)
    .environment(MissionManager.mock)
    .environment(AuthManager(session: .guest))
    .environment(ThemeManager.shared)
    .environment(PremiumManager.shared)
    .preferredColorScheme(.dark)
}
