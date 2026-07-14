import SwiftUI

struct ContentView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var themeManager = ThemeManager.shared
    @State private var premiumManager = PremiumManager.shared
    @State private var notificationManager = NotificationManager()
    @State private var missionManager = MissionManager()
    @State private var authManager = AuthManager(loadFromStorage: true)
    @State private var deepLinkCoordinator = DeepLinkCoordinator()
    @State private var isShowingLoginChoice = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                        isShowingLoginChoice = true
                    }
                }
                .transition(.opacity)
            }
        }
        .environment(notificationManager)
        .environment(missionManager)
        .environment(authManager)
        .environment(deepLinkCoordinator)
        .environment(themeManager)
        .environment(premiumManager)
        .appToastOverlay()
        .onAppear {
            missionManager.syncSessionScope()
            themeManager.resetToFreeThemeIfNeeded(isPremium: premiumManager.isPremium)
        }
        .onChange(of: premiumManager.isPremium) { _, isPremium in
            themeManager.resetToFreeThemeIfNeeded(isPremium: isPremium)
        }
        .onChange(of: authManager.session) {
            missionManager.syncSessionScope()
            Task {
                await premiumManager.refreshServerSubscription(accessToken: authManager.accessToken)
                await premiumManager.syncCurrentEntitlements(accessToken: authManager.accessToken)
                await missionManager.refreshSystemConcepts(accessToken: authManager.accessToken)
            }
        }
        .task {
            premiumManager.startStoreKitObservation()
            await premiumManager.refreshPurchasedProducts()
            await premiumManager.refreshServerSubscription(accessToken: authManager.accessToken)
            await premiumManager.syncCurrentEntitlements(accessToken: authManager.accessToken)
            await missionManager.refreshSystemConcepts(accessToken: authManager.accessToken)
        }
        .onOpenURL { url in
            deepLinkCoordinator.handle(url)
        }
        .fullScreenCover(isPresented: $isShowingLoginChoice) {
            LoginView {
                isShowingLoginChoice = false
                hasCompletedOnboarding = true
            }
            .environment(authManager)
        }
        .preferredColorScheme(themeManager.preferredColorScheme)
        .id(themeManager.selectedTheme.id)
        .task {
            await notificationManager.refreshAuthorizationStatus()
            if notificationManager.isEnabled {
                await notificationManager.scheduleDailyNotifications(missionManager: missionManager)
            }
        }
    }
}

#Preview {
    ContentView()
}
