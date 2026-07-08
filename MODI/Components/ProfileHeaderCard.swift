import SwiftUI

struct ProfileHeaderCard: View {

    let nickname: String
    let tagline: String
    let stats: DiscoveryStats
    let nameSuffix: String

    init(
        nickname: String,
        tagline: String,
        stats: DiscoveryStats,
        nameSuffix: String = "님"
    ) {
        self.nickname = nickname
        self.tagline = tagline
        self.stats = stats
        self.nameSuffix = nameSuffix
    }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            profileImage

            VStack(spacing: AppSpacing.xs) {
                Text("\(nickname)\(nameSuffix)")
                    .font(AppFont.title2)
                    .foregroundStyle(AppColor.Text.primary)

                Text(tagline)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.Text.secondary)
            }

            if stats.streakDays > 0 {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColor.Semantic.warning)

                    Text("\(stats.streakDays)일 연속 발견 중")
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                }
            }

            VStack(spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.sm) {
                    StatCard(
                        value: "\(stats.totalRecords)",
                        label: "총 발견"
                    )
                    StatCard(
                        value: "\(stats.completedConcepts)",
                        label: "참여 컨셉"
                    )
                }

                HStack(spacing: AppSpacing.sm) {
                    StatCard(
                        value: "\(stats.completedCollections)",
                        label: "컬렉션"
                    )
                    StatCard(
                        value: "\(stats.streakDays)일",
                        label: "연속 기록"
                    )
                }
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

#Preview("Light") {
    ProfileHeaderCard(nickname: "영임", tagline: "MODI Explorer", stats: .mock)
        .appScreenPadding()
        .appScreenBackground()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ProfileHeaderCard(nickname: "영임", tagline: "MODI Explorer", stats: .mock)
        .appScreenPadding()
        .appScreenBackground()
        .preferredColorScheme(.dark)
}
