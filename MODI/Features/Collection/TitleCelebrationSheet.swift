import SwiftUI

// MARK: - TitleCelebrationSheet

struct TitleCelebrationSheet: View {

    let celebration: TitleCelebration
    var onContinue: () -> Void
    var onShare: () -> Void

    @State private var isVisible = false
    @State private var sparkleRotation: Double = 0

    var body: some View {
        VStack(spacing: AppSpacing.xxl) {
            Spacer()

            celebrationContent
                .scaleEffect(isVisible ? 1 : 0.88)
                .opacity(isVisible ? 1 : 0)

            Spacer()

            actionButtons
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, AppSpacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.Background.primary)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                isVisible = true
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
        }
    }

    private var celebrationContent: some View {
        VStack(spacing: AppSpacing.xl) {
            Text("✨ 새 배너")
                .font(AppFont.Rounded.headline)
                .foregroundStyle(AppColor.Text.secondary)
                .tracking(0.6)

            ZStack {
                Text("✨")
                    .font(.system(size: 28))
                    .opacity(0.45)
                    .rotationEffect(.degrees(sparkleRotation))
                    .offset(x: -52, y: -36)

                Text(celebration.emoji)
                    .font(.system(size: 64))

                Text("✨")
                    .font(.system(size: 22))
                    .opacity(0.35)
                    .rotationEffect(.degrees(-sparkleRotation * 0.7))
                    .offset(x: 48, y: 28)
            }
            .frame(height: 88)

            VStack(spacing: AppSpacing.sm) {
                Text(celebration.title.name)
                    .font(AppFont.Rounded.title)
                    .foregroundStyle(AppColor.Text.primary)
                    .multilineTextAlignment(.center)

                Text("\(celebration.totalDiscoveries) Discoveries")
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.Text.secondary)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: AppSpacing.md) {
            Button("계속 발견하기", action: onContinue)
                .buttonStyle(PrimaryButtonStyle())

            Button("공유하기", action: onShare)
                .buttonStyle(SecondaryButtonStyle())
        }
    }
}

#Preview("Light") {
    TitleCelebrationSheet(
        celebration: TitleCelebration(
            conceptID: Concept.mock.id,
            collectionTitle: "Cloud Hunter",
            emoji: "☁️",
            title: CollectionTitle(name: "Cloud Chaser", milestone: 30),
            totalDiscoveries: 30
        ),
        onContinue: {},
        onShare: {}
    )
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    TitleCelebrationSheet(
        celebration: TitleCelebration(
            conceptID: Concept.mock.id,
            collectionTitle: "Cloud Hunter",
            emoji: "☁️",
            title: CollectionTitle(name: "Cloud Chaser", milestone: 30),
            totalDiscoveries: 30
        ),
        onContinue: {},
        onShare: {}
    )
    .preferredColorScheme(.dark)
}
