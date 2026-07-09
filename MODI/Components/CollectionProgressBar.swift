import SwiftUI

// MARK: - CollectionProgressBar

struct CollectionProgressBar: View {

    let progress: Double
    var height: CGFloat = 4
    var animated: Bool = true

    @State private var displayedProgress: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColor.Background.secondary)

                Capsule()
                    .fill(AppColor.Accent.primary)
                    .frame(width: geometry.size.width * displayedProgress)
            }
        }
        .frame(height: height)
        .onAppear {
            updateProgress(animated: animated)
        }
        .onChange(of: progress) {
            updateProgress(animated: animated)
        }
    }

    private func updateProgress(animated: Bool) {
        let clamped = min(1, max(0, progress))
        if animated {
            withAnimation(.easeOut(duration: 0.6)) {
                displayedProgress = clamped
            }
        } else {
            displayedProgress = clamped
        }
    }
}

#Preview("Light") {
    VStack(spacing: AppSpacing.lg) {
        CollectionProgressBar(progress: 0.6)
        CollectionProgressBar(progress: 0.25)
        CollectionProgressBar(progress: 1.0)
    }
    .padding()
    .appScreenBackground()
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(spacing: AppSpacing.lg) {
        CollectionProgressBar(progress: 0.6)
        CollectionProgressBar(progress: 0.25)
        CollectionProgressBar(progress: 1.0)
    }
    .padding()
    .appScreenBackground()
    .preferredColorScheme(.dark)
}
