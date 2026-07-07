import SwiftUI

struct CollectionCard: View {

    let collection: PhotoCollection
    let photoCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                .fill(collection.themeColor)
                .aspectRatio(1.0, contentMode: .fit)
                .overlay {
                    Text(collection.emoji)
                        .font(.system(size: 36))
                }
                .overlay(alignment: .topTrailing) {
                    if photoCount > 0 {
                        Text("\(photoCount)")
                            .font(AppFont.caption2)
                            .foregroundStyle(AppColor.Text.onAccent)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(AppColor.Accent.primary, in: Capsule())
                            .padding(AppSpacing.sm)
                    }
                }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(collection.title)
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1)

                Text(photoCount > 0 ? "사진 \(photoCount)장" : collection.missionPrompt)
                    .font(AppFont.caption1)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(photoCount > 0 ? 1 : 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .appCardStyle(padding: AppSpacing.md)
    }
}

#Preview {
    CollectionCard(collection: PhotoCollection.builtIn[0], photoCount: 3)
        .frame(width: 170)
        .appScreenPadding()
        .appScreenBackground()
}
