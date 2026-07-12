import SwiftUI

struct ContentView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("settings.app.appearanceMode") private var appearanceModeRaw = AppAppearanceMode.system.rawValue
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
        .appToastOverlay()
        .onAppear {
            missionManager.syncSessionScope()
        }
        .onChange(of: authManager.session) {
            missionManager.syncSessionScope()
            Task {
                await missionManager.refreshSystemConcepts(accessToken: authManager.accessToken)
            }
        }
        .task {
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
        .preferredColorScheme(appAppearanceMode.colorScheme)
        .task {
            await notificationManager.refreshAuthorizationStatus()
            if notificationManager.isEnabled {
                await notificationManager.scheduleDailyNotifications(missionManager: missionManager)
            }
        }
    }

    private var appAppearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }
}

#Preview {
    ContentView()
}
