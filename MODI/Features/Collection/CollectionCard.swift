import SwiftUI

struct CollectionCard: View {

    let collection: MODICollection
    let photoCount: Int
    var latestRecordDate: Date?

    private var latestDateLabel: String? {
        guard let latestRecordDate else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: latestRecordDate)
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

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(collection.title)
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1)

                if photoCount > 0 {
                    Text("사진 \(photoCount)장")
                        .font(AppFont.caption1)
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(1)

                    if let latestDateLabel {
                        Text("최근 \(latestDateLabel)")
                            .font(AppFont.caption2)
                            .foregroundStyle(AppColor.Text.tertiary)
                            .lineLimit(1)
                    }
                } else {
                    Text(collection.missionPrompt)
                        .font(AppFont.caption1)
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
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

#Preview("Light") {
    let collection = MODICollection.from(
        photoCollection: PhotoCollection.builtIn[0],
        type: .system
    )

    return CollectionCard(
        collection: collection,
        photoCount: 3,
        latestRecordDate: .now
    )
    .frame(width: 170)
    .appScreenPadding()
    .appScreenBackground()
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    let collection = MODICollection.from(
        photoCollection: PhotoCollection.builtIn[0],
        type: .system
    )

    return CollectionCard(
        collection: collection,
        photoCount: 3,
        latestRecordDate: .now
    )
    .frame(width: 170)
    .appScreenPadding()
    .appScreenBackground()
    .preferredColorScheme(.dark)
}
