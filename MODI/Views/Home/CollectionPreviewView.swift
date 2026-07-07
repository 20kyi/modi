import SwiftUI

struct CollectionPreviewView: View {

    let collections: [CollectionPreviewItem]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("내 컬렉션")
                .font(AppFont.title3)
                .foregroundStyle(AppColor.Text.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.itemGap) {
                    ForEach(collections) { collection in
                        collectionCard(collection)
                    }
                }
            }
        }
    }

    private func collectionCard(_ collection: CollectionPreviewItem) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                .fill(collection.themeColor)
                .frame(width: 120, height: 100)
                .overlay {
                    Text(collection.emoji)
                        .font(.system(size: 36))
                }
                .overlay(alignment: .bottomTrailing) {
                    Text("\(collection.photoCount)장")
                        .font(AppFont.caption2)
                        .foregroundStyle(AppColor.Text.onAccent)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(AppColor.Accent.primary.opacity(0.85), in: Capsule())
                        .padding(AppSpacing.sm)
                }

            Text(collection.title)
                .font(AppFont.subheadline)
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(1)
        }
        .frame(width: 120)
    }
}

#Preview {
    CollectionPreviewView(collections: CollectionPreviewItem.mockList)
        .appScreenPadding()
        .appScreenBackground()
}
