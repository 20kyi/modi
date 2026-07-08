import SwiftData
import SwiftUI

// MARK: - CollectionShareCardView

/// Instagram Story/Feed 공유용 컬렉션 카드 이미지.
struct CollectionShareCardView: View {

    let collection: MODICollection
    let records: [MODIRecord]

    static let cardSize = CGSize(width: 360, height: 640)

    private let gridColumns = [
        GridItem(.flexible(), spacing: AppSpacing.sm),
        GridItem(.flexible(), spacing: AppSpacing.sm),
        GridItem(.flexible(), spacing: AppSpacing.sm)
    ]

    private var displayRecords: [MODIRecord] {
        Array(records.sorted { $0.createdAt > $1.createdAt }.prefix(6))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    collection.themeColor,
                    collection.themeColor.opacity(0.72),
                    AppColor.Background.primary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: AppSpacing.xl) {
                headerSection
                photoGridSection
                Spacer(minLength: AppSpacing.md)
                progressSection
                modiBranding
            }
            .padding(.horizontal, AppSpacing.xxl)
            .padding(.vertical, AppSpacing.xxxl)
        }
        .frame(width: Self.cardSize.width, height: Self.cardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: AppShadow.medium.color, radius: AppShadow.medium.radius, x: 0, y: AppShadow.medium.yOffset)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text(collection.emoji)
                .font(.system(size: 52))

            Text(collection.title)
                .font(AppFont.Rounded.title)
                .foregroundStyle(AppColor.Text.primary)
                .multilineTextAlignment(.center)

            Text(collection.discoveryCountLabel)
                .font(AppFont.subheadline)
                .foregroundStyle(AppColor.Text.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var photoGridSection: some View {
        LazyVGrid(columns: gridColumns, spacing: AppSpacing.sm) {
            ForEach(0..<6, id: \.self) { index in
                photoCell(at: index)
            }
        }
        .padding(AppSpacing.md)
        .background(
            AppColor.Surface.card.opacity(0.88),
            in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        )
    }

    @ViewBuilder
    private func photoCell(at index: Int) -> some View {
        Group {
            if index < displayRecords.count {
                MODIRecordImage(record: displayRecords[index])
                    .aspectRatio(1, contentMode: .fill)
            } else {
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .fill(collection.themeColor.opacity(0.45))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(AppColor.Text.tertiary)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
    }

    private var progressSection: some View {
        VStack(spacing: AppSpacing.sm) {
            if collection.isCollectionComplete {
                Text("COMPLETE ✨")
                    .font(AppFont.Rounded.headline)
                    .foregroundStyle(AppColor.Text.primary)
            } else {
                ProgressView(value: collection.completionRate)
                    .tint(AppColor.Accent.primary)
                    .scaleEffect(x: 1, y: 1.6, anchor: .center)

                Text(collection.progressStatusLabel)
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var modiBranding: some View {
        Text("MODI")
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .tracking(2.4)
            .foregroundStyle(AppColor.Text.tertiary)
    }
}

// MARK: - Image Rendering

extension CollectionShareCardView {

    @MainActor
    static func renderedImage(
        for collection: MODICollection,
        records: [MODIRecord],
        scale: CGFloat = 3.0
    ) -> UIImage? {
        let card = CollectionShareCardView(collection: collection, records: records)
        let renderer = ImageRenderer(content: card)
        renderer.scale = scale
        return renderer.uiImage
    }
}

// MARK: - Preview

#Preview("In Progress") {
    CollectionShareCardView(
        collection: previewCollection(currentCount: 12),
        records: previewRecords(count: 5)
    )
    .padding()
    .background(AppColor.Background.grouped)
}

#Preview("Complete") {
    CollectionShareCardView(
        collection: previewCollection(currentCount: 20),
        records: previewRecords(count: 6)
    )
    .padding()
    .background(AppColor.Background.grouped)
}

// MARK: - Preview Helpers

private func previewCollection(currentCount: Int) -> MODICollection {
    let collection = MODICollection.from(
        photoCollection: PhotoCollection.builtIn[6],
        type: .system
    )
    collection.targetCount = 20
    _ = currentCount
    return collection
}

private func previewRecords(count: Int) -> [MODIRecord] {
    let colors: [UIColor] = [.systemTeal, .systemBlue, .systemIndigo, .systemCyan, .systemMint, .systemPurple]
    return (0..<count).compactMap { index in
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            colors[index % colors.count].setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        guard let imageData = image.jpegData(compressionQuality: 0.85) else { return nil }

        return MODIRecord(
            imageData: imageData,
            conceptId: Concept.mock.id,
            conceptTitle: Concept.mock.title,
            conceptEmoji: Concept.mock.emoji,
            createdAt: Calendar.current.date(byAdding: .day, value: -index, to: .now)!
        )
    }
}
