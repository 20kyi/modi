import SwiftUI

struct ContentView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    ContentView()
}
