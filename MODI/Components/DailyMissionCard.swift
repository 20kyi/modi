import SwiftUI

struct DailyMissionCard: View {

    let mission: DailyMission
    let collection: PhotoCollection
    var isCompleted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("오늘의 미션")
                    .font(AppFont.caption1)
                    .foregroundStyle(AppColor.Text.secondary)

                Spacer()

                if isCompleted {
                    Label("완료", systemImage: "checkmark.circle.fill")
                        .font(AppFont.caption1)
                        .foregroundStyle(AppColor.Semantic.success)
                }
            }

            HStack(spacing: AppSpacing.md) {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(collection.themeColor)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Text(collection.emoji)
                            .font(.system(size: 28))
                    }

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(mission.prompt)
                        .font(AppFont.title3)
                        .foregroundStyle(AppColor.Text.primary)

                    Text("\(collection.title) 컬렉션에 추가돼요")
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(
            collection.themeColor.opacity(0.35),
            in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        )
    }
}

#Preview {
    DailyMissionCard(
        mission: DailyMission(collectionID: PhotoCollection.builtIn[0].id, prompt: "분홍색을 찍으세요"),
        collection: PhotoCollection.builtIn[0]
    )
    .appScreenPadding()
    .appScreenBackground()
}
