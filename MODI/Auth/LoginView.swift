import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager

    /// 온보딩/프로필 진입 후, 로그인 선택을 완료하면 호출됩니다.
    let onComplete: () -> Void

    @AppStorage("modi.openCollectionAfterInitialLoad") private var openCollectionAfterInitialLoad = false
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: AppSpacing.lg) {
                header
                contentCard
            }

            Spacer()
        }
        .appScreenBackground()
    }

    private var header: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("MODI")
                .font(AppFont.headline)
                .foregroundStyle(AppColor.Text.primary)
                .frame(maxWidth: .infinity, alignment: .center)

            Text("작은 순간을 발견하고 기록하세요 ✨")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.Text.secondary)
                .lineSpacing(6)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .appScreenPadding()
    }

    private var contentCard: some View {
        VStack(spacing: AppSpacing.md) {
            if let errorMessage {
                Text(errorMessage)
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Semantic.error)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                startAppleSignIn()
            } label: {
                ZStack {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColor.Text.onButton)

                        Text("Apple로 시작하기")
                            .font(AppFont.headline)
                            .foregroundStyle(AppColor.Text.onButton)
                    }

                    HStack {
                        Spacer()
                        if isSigningIn {
                            ProgressView()
                                .tint(AppColor.Text.onButton)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .frame(height: AppSpacing.minTouchTarget)
                .background(AppColor.Accent.buttonFill, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isSigningIn)

            Button("게스트로 둘러보기") {
                authManager.setGuest()
                onComplete()
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(isSigningIn)
        }
        .appCardStyle()
        .padding(.horizontal, AppSpacing.cardPadding)
    }

    private func startAppleSignIn() {
        isSigningIn = true
        errorMessage = nil

        Task {
            do {
                _ = try await authManager.signInWithApple()
                openCollectionAfterInitialLoad = true
                onComplete()
            } catch {
                errorMessage = error.localizedDescription
            }

            isSigningIn = false
        }
    }
}

// MARK: - Preview

#Preview("Light") {
    LoginView(onComplete: {})
        .environment(AuthManager.mock)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    LoginView(onComplete: {})
        .environment(AuthManager.mock)
        .preferredColorScheme(.dark)
}

