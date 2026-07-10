import SwiftUI

// MARK: - DataLoadingView

/// 로그인 후 서버 데이터를 불러오는 동안 표시하는 MODI 스타일 로딩 화면입니다.
struct DataLoadingView: View {

    private let messages = [
        "✨ 컬렉션을 준비하는 중",
        "📸 기록을 불러오는 중",
        "🎨 미션을 꾸미는 중"
    ]

    @State private var currentIndex = 0
    @State private var messageOpacity: Double = 1

    private let stepInterval: Duration = .seconds(2.8)
    private let fadeDuration: TimeInterval = 0.45

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: AppSpacing.xl) {
                Text("MODI")
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Text.primary)

                VStack(spacing: AppSpacing.lg) {
                    ProgressView()
                        .controlSize(.regular)
                        .tint(AppColor.Accent.primary)

                    Text(messages[currentIndex])
                        .font(AppFont.subheadline)
                        .foregroundStyle(AppColor.Text.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(messageOpacity)
                }
            }

            Spacer()
        }
        .appScreenBackground()
        .task {
            await runMessageCycle()
        }
    }

    @MainActor
    private func runMessageCycle() async {
        currentIndex = 0
        messageOpacity = 1

        for nextIndex in 1..<messages.count {
            try? await Task.sleep(for: stepInterval)
            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: fadeDuration)) {
                messageOpacity = 0
            }

            try? await Task.sleep(for: .milliseconds(Int(fadeDuration * 1000)))
            guard !Task.isCancelled else { return }

            currentIndex = nextIndex

            withAnimation(.easeInOut(duration: fadeDuration)) {
                messageOpacity = 1
            }
        }
    }
}

#Preview {
    DataLoadingView()
}
