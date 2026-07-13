import SwiftUI

struct CollectionCard: View {

    enum SlotBadge {
        case none
        case basic
        case premium
    }

    let collection: MODICollection
    let photoCount: Int
    var slotBadge: SlotBadge = .none

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
                .overlay(alignment: .topLeading) {
                    if slotBadge != .none {
                        Text(slotBadgeTitle)
                            .font(AppFont.caption2)
                            .foregroundStyle(slotBadgeForeground)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(slotBadgeBackground, in: Capsule())
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

    private var slotBadgeTitle: String {
        switch slotBadge {
        case .none:
            ""
        case .basic:
            "기본 슬롯"
        case .premium:
            "MODI+"
        }
    }

    private var slotBadgeForeground: Color {
        switch slotBadge {
        case .premium:
            AppColor.Text.onAccent
        case .none, .basic:
            AppColor.Text.primary
        }
    }

    private var slotBadgeBackground: AnyShapeStyle {
        switch slotBadge {
        case .premium:
            AnyShapeStyle(AppColor.Accent.primary)
        case .none, .basic:
            AnyShapeStyle(.ultraThinMaterial)
        }
    }
}

extension CollectionCard {
    init(collection: PhotoCollection, photoCount: Int, slotBadge: SlotBadge = .none) {
        self.init(
            collection: MODICollection.from(
                photoCollection: collection,
                type: collection.category == .custom ? .custom : .system
            ),
            photoCount: photoCount,
            slotBadge: slotBadge
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
