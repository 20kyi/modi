import SwiftUI

struct DailyMissionCard: View {

    let mission: DailyMission
    var onRecordTapped: (() -> Void)?
    var canChangeMission: Bool = false
    var onChangeMissionTapped: (() -> Void)?

    private var palette: AppColor.ThemePalette {
        AppColor.themePalette(from: mission.themeColorHex)
    }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Text(mission.emoji)
                .font(.system(size: 56))

            VStack(spacing: AppSpacing.sm) {
                Text(mission.title)
                    .font(AppFont.title2)
                    .foregroundStyle(AppColor.Text.primary)
                    .multilineTextAlignment(.center)

                Text(mission.description)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.Text.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if mission.isCompleted {
                MissionCompletedBadge(palette: palette)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    if let onRecordTapped {
                        Button(action: onRecordTapped) {
                            Text("기록하기")
                        }
                        .buttonStyle(ThemeButtonStyle(palette: palette))
                    }

                    if canChangeMission, let onChangeMissionTapped {
                        Button("미션 바꾸기", action: onChangeMissionTapped)
                            .font(AppFont.footnote)
                            .foregroundStyle(AppColor.Text.secondary)
                    }
                }
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            mission.themeColor.opacity(0.45),
            in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .strokeBorder(mission.themeColor.opacity(0.6), lineWidth: 1)
        }
        .appShadow(.medium)
    }
}

// MARK: - Mission Completed Badge

private struct MissionCompletedBadge: View {
    let palette: AppColor.ThemePalette

    @State private var isAnimated = false

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .symbolEffect(.bounce, value: isAnimated)
                .scaleEffect(isAnimated ? 1 : 0.6)
                .opacity(isAnimated ? 1 : 0)

            Text("미션 완료")
                .font(AppFont.headline)
        }
        .foregroundStyle(palette.completedForeground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .background {
            ZStack {
                palette.softFill

                palette.accent.opacity(0.10)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(palette.accent.opacity(0.28), lineWidth: 1)
        }
        .scaleEffect(isAnimated ? 1 : 0.97)
        .opacity(isAnimated ? 1 : 0.85)
        .onAppear {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.72)) {
                isAnimated = true
            }
        }
    }
}

#Preview("진행 중") {
    DailyMissionCard(mission: .mock) {}
        .appScreenPadding()
        .appScreenBackground()
        .preferredColorScheme(.light)
}

#Preview("완료") {
    DailyMissionCard(mission: .mockCompleted)
        .appScreenPadding()
        .appScreenBackground()
        .preferredColorScheme(.light)
}

#Preview("진행 중 · Dark") {
    DailyMissionCard(mission: .mock) {}
        .appScreenPadding()
        .appScreenBackground()
        .preferredColorScheme(.dark)
}

#Preview("완료 · Dark") {
    DailyMissionCard(mission: .mockCompleted)
        .appScreenPadding()
        .appScreenBackground()
        .preferredColorScheme(.dark)
}

#Preview("완료 · Pink") {
    DailyMissionCard(
        mission: DailyMission(
            title: "Pink Love",
            emoji: "🩷",
            description: "분홍빛 순간을 찾아보세요",
            category: .nature,
            themeColorHex: "F8DDE8",
            collectionID: UUID(),
            isCompleted: true
        )
    )
    .appScreenPadding()
    .appScreenBackground()
    .preferredColorScheme(.light)
}
