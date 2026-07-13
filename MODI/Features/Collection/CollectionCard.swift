import SwiftUI

struct CollectionCard: View {

    let collection: MODICollection
    let photoCount: Int

    private var progress: CollectionProgress {
        CollectionProgress.make(conceptID: collection.id, totalDiscoveries: photoCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                .fill(AppColor.emojiBackground(from: collection.themeColorHex))
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
                .overlay(alignment: .bottomLeading) {
                    if let badgeName = progress.currentTitle?.name {
                        Text(badgeName)
                            .font(AppFont.caption2)
                            .foregroundStyle(AppColor.Text.primary)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(AppSpacing.sm)
                    }
                }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(collection.title)
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1)

                Text(collection.missionPrompt)
                    .font(AppFont.caption1)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .appCardStyle(padding: AppSpacing.md)
    }
}

extension CollectionCard {
    init(collection: PhotoCollection, photoCount: Int) {
        self.init(
            collection: MODICollection.from(
                photoCollection: collection,
                type: collection.category == .custom ? .custom : .system
            ),
            photoCount: photoCount
        )
    }
}

#Preview("With Records — Light") {
    let collection = MODICollection.from(
        photoCollection: PhotoCollection.builtIn[6],
        type: .system
    )

    return CollectionCard(collection: collection, photoCount: 12)
        .frame(width: 170)
        .appScreenPadding()
        .appScreenBackground()
        .preferredColorScheme(.light)
}

#Preview("With Records — Dark") {
    let collection = MODICollection.from(
        photoCollection: PhotoCollection.builtIn[6],
        type: .system
    )

    return CollectionCard(collection: collection, photoCount: 12)
        .frame(width: 170)
        .appScreenPadding()
        .appScreenBackground()
        .preferredColorScheme(.dark)
}

#Preview("Empty") {
    let collection = MODICollection.from(
        photoCollection: PhotoCollection.builtIn[6],
        type: .system
    )

    return CollectionCard(collection: collection, photoCount: 0)
        .frame(width: 170)
        .appScreenPadding()
        .appScreenBackground()
}
