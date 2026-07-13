import SwiftUI

struct DailyMissionCard: View {

    let mission: DailyMission
    var onRecordTapped: (() -> Void)?
    var canOfferMissionChange: Bool = false
    var showsMissionChangeButton: Bool = false
    var remainingMissionChanges: Int?
    var onChangeMissionTapped: (() -> Void)?
    var previewThemeColors: ThemeColors? = nil

    private var palette: AppColor.ThemePalette {
        AppColor.themePalette(from: mission.themeColorHex)
    }

    private var titleColor: Color {
        previewThemeColors?.text ?? AppColor.Text.primary
    }

    private var descriptionColor: Color {
        previewThemeColors?.subText ?? AppColor.Text.secondary
    }

    private var tertiaryColor: Color {
        previewThemeColors?.textTertiary ?? AppColor.Text.tertiary
    }

    private var cardShadowColor: Color {
        previewThemeColors?.shadowMedium ?? AppColor.Shadow.medium
    }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Text(mission.emoji)
                .font(.system(size: 56))

            VStack(spacing: AppSpacing.sm) {
                Text(mission.title)
                    .font(AppFont.title2)
                    .foregroundStyle(titleColor)
                    .multilineTextAlignment(.center)

                Text(mission.description)
                    .font(AppFont.callout)
                    .foregroundStyle(descriptionColor)
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

                    if canOfferMissionChange {
                        VStack(spacing: AppSpacing.xs) {
                            if showsMissionChangeButton, let onChangeMissionTapped {
                                Button("미션 바꾸기", action: onChangeMissionTapped)
                                    .font(AppFont.footnote)
                                    .foregroundStyle(descriptionColor)
                            }

                            if let remainingMissionChanges {
                                Text(remainingMissionChangesLabel(remainingMissionChanges))
                                    .font(AppFont.caption1)
                                    .foregroundStyle(tertiaryColor)
                            }
                        }
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
        .shadow(color: cardShadowColor, radius: 8, x: 0, y: 4)
    }

    private func remainingMissionChangesLabel(_ remaining: Int) -> String {
        if remaining == 0 {
            return "오늘 변경 횟수를 모두 사용했어요"
        }
        return "오늘 \(remaining)회 남음"
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

#Preview("진행 중 · 남은 횟수") {
    DailyMissionCard(
        mission: .mock,
        canOfferMissionChange: true,
        showsMissionChangeButton: true,
        remainingMissionChanges: 2
    ) {}
        .appScreenPadding()
        .appScreenBackground()
        .preferredColorScheme(.light)
}

#Preview("진행 중 · 횟수 소진") {
    DailyMissionCard(
        mission: .mock,
        canOfferMissionChange: true,
        showsMissionChangeButton: false,
        remainingMissionChanges: 0
    ) {}
        .appScreenPadding()
        .appScreenBackground()
        .preferredColorScheme(.light)
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
