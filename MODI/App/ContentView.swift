import SwiftUI

struct ContentView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var notificationManager = NotificationManager()
    @State private var missionManager = MissionManager()
    @State private var authManager = AuthManager(loadFromStorage: true)
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
        .fullScreenCover(isPresented: $isShowingLoginChoice) {
            LoginView {
                isShowingLoginChoice = false
                hasCompletedOnboarding = true
            }
            .environment(authManager)
        }
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
