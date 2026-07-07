import SwiftUI

struct ProfileHeaderCard: View {

    let profile: UserProfile
    let tagline: String

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            profileImage

            VStack(spacing: AppSpacing.xs) {
                Text("\(profile.nickname)님")
                    .font(AppFont.title2)
                    .foregroundStyle(AppColor.Text.primary)

                Text(tagline)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.Text.secondary)
            }

            HStack(spacing: AppSpacing.sm) {
                StatCard(
                    value: "\(profile.totalRecords)",
                    label: "총 기록"
                )
                StatCard(
                    value: "\(profile.totalConcepts)",
                    label: "참여 컨셉"
                )
                StatCard(
                    value: "\(profile.streakDays)일",
                    label: "연속 기록"
                )
            }
        }
        .appCardStyle()
    }

    private var profileImage: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppColor.Accent.soft, AppColor.Background.tertiary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 88, height: 88)

            Image(systemName: "person.fill")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(AppColor.Accent.primary)
        }
        .overlay {
            Circle()
                .strokeBorder(AppColor.Border.subtle, lineWidth: 1)
        }
    }
}

#Preview {
    ProfileHeaderCard(profile: .mock, tagline: "MODI Explorer")
        .appScreenPadding()
        .appScreenBackground()
}
