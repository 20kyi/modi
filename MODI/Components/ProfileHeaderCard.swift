import SwiftUI

struct ProfileHeaderCard: View {

    let nickname: String
    let tagline: String
    let stats: DiscoveryStats
    let nameSuffix: String
    let isPremium: Bool
    let missionPlaceholder: ProfileTopCollection?

    init(
        nickname: String,
        tagline: String,
        stats: DiscoveryStats,
        nameSuffix: String = "님",
        isPremium: Bool = false,
        missionPlaceholder: ProfileTopCollection? = nil
    ) {
        self.nickname = nickname
        self.tagline = tagline
        self.stats = stats
        self.nameSuffix = nameSuffix
        self.isPremium = isPremium
        self.missionPlaceholder = missionPlaceholder
    }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            if let topCollection = stats.topCollection {
                collectionBadge(topCollection, accessibilityLabel: "가장 많이 기록한 컬렉션")
            } else if let missionPlaceholder {
                collectionBadge(missionPlaceholder, accessibilityLabel: "오늘의 미션")
            }

            VStack(spacing: AppSpacing.sm) {
                Text("\(nickname)\(nameSuffix)")
                    .font(AppFont.title2)
                    .foregroundStyle(AppColor.Text.primary)

                if isPremium {
                    Text("✨ MODI+")
                        .font(AppFont.caption1.weight(.semibold))
                        .foregroundStyle(AppColor.Semantic.warning)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(
                            AppColor.Semantic.warning.opacity(0.12),
                            in: Capsule(style: .continuous)
                        )
                        .padding(.bottom, AppSpacing.xs)
                        .accessibilityLabel("MODI+ 프리미엄")
                }

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
                        value: "\(stats.activeCollections)",
                        label: "컬렉션"
                    )
                }

                HStack(spacing: AppSpacing.sm) {
                    StatCard(
                        value: "\(stats.earnedBannerCount)",
                        label: "획득 배너"
                    )
                    StatCard(
                        value: "\(stats.monthlyRecords)",
                        label: "이번 달 발견"
                    )
                }
            }
        }
        .appCardStyle()
    }

    private func collectionBadge(
        _ collection: ProfileTopCollection,
        accessibilityLabel: String
    ) -> some View {
        Circle()
            .fill(AppColor.emojiBackground(from: collection.themeColorHex))
            .frame(width: 88, height: 88)
            .overlay {
                Text(collection.emoji)
                    .font(.system(size: 36))
            }
            .overlay {
                Circle()
                    .strokeBorder(AppColor.Border.subtle, lineWidth: 1)
            }
            .accessibilityLabel(accessibilityLabel)
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

#Preview("Premium") {
    ProfileHeaderCard(
        nickname: "영임",
        tagline: "MODI Explorer",
        stats: .mock,
        isPremium: true
    )
    .appScreenPadding()
    .appScreenBackground()
}

#Preview("No Records Placeholder") {
    ProfileHeaderCard(
        nickname: "MODI Explorer",
        tagline: "작은 순간을 발견하는 중",
        stats: .empty,
        nameSuffix: "",
        missionPlaceholder: ProfileTopCollection(emoji: "☁️", themeColorHex: "E4ECF4")
    )
    .appScreenPadding()
    .appScreenBackground()
}
