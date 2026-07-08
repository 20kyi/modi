import SwiftUI

struct DailyMissionCard: View {

    let mission: DailyMission
    var onRecordTapped: (() -> Void)?
    var canChangeMission: Bool = false
    var onChangeMissionTapped: (() -> Void)?

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
                Label("미션 완료", systemImage: "checkmark.circle.fill")
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Semantic.success)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        AppColor.Semantic.success.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    )
            } else {
                VStack(spacing: AppSpacing.sm) {
                    if let onRecordTapped {
                        Button(action: onRecordTapped) {
                            Text("기록하기")
                        }
                        .buttonStyle(PrimaryButtonStyle())
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

#Preview("진행 중") {
    DailyMissionCard(mission: .mock) {}
        .appScreenPadding()
        .appScreenBackground()
}

#Preview("완료") {
    DailyMissionCard(mission: .mockCompleted)
        .appScreenPadding()
        .appScreenBackground()
}
