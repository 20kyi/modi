import SwiftUI

// MARK: - VideoGenerationStage

enum VideoGenerationStage: Int, CaseIterable, Sendable {
    case preparingCollection
    case generatingAnimation
    case renderingVideo
    case saving
}

// MARK: - VideoGenerationProgressView

struct VideoGenerationProgressView: View {

    private let messages = [
        "🖼 아이템을 정리하는 중",
        "🎞 움직임을 더하는 중",
        "✨ 감성을 완성하는 중"
    ]

    @State private var currentIndex = 0
    @State private var messageOpacity: Double = 1

    private let stepInterval: Duration = .seconds(2.8)
    private let fadeDuration: TimeInterval = 0.45

    var body: some View {
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
        .padding(.horizontal, AppSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    Color.clear
        .aspectRatio(9 / 16, contentMode: .fit)
        .overlay {
            VideoGenerationProgressView()
        }
        .padding()
        .appScreenBackground()
}
