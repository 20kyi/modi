import SwiftUI

struct CollectionDetailView: View {

    @Environment(CollectionStore.self) private var store

    let collection: PhotoCollection

    @State private var entryPendingDeletion: MissionEntry?

    private var entries: [MissionEntry] {
        store.entries(for: collection.id)
    }

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.gridGutter),
        GridItem(.flexible(), spacing: AppSpacing.gridGutter),
        GridItem(.flexible(), spacing: AppSpacing.gridGutter)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                headerSection
                photosSection
            }
            .appScreenPadding()
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .appScreenBackground()
        .navigationTitle(collection.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("이 사진을 삭제할까요?", isPresented: deletionAlertIsPresented, presenting: entryPendingDeletion) { entry in
            Button("삭제", role: .destructive) {
                store.removeEntry(id: entry.id)
                entryPendingDeletion = nil
            }
            Button("취소", role: .cancel) {
                entryPendingDeletion = nil
            }
        } message: { _ in
            Text("삭제한 사진은 복구할 수 없어요.")
        }
    }

    private var deletionAlertIsPresented: Binding<Bool> {
        Binding(
            get: { entryPendingDeletion != nil },
            set: { if !$0 { entryPendingDeletion = nil } }
        )
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(collection.themeColor)
                    .frame(width: 72, height: 72)
                    .overlay {
                        Text(collection.emoji)
                            .font(.system(size: 36))
                    }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(collection.missionPrompt)
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.Text.primary)

                    Text(collection.description)
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                }
            }

            Text("\(entries.count)장의 사진")
                .font(AppFont.caption1)
                .foregroundStyle(AppColor.Text.tertiary)
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if entries.isEmpty {
                EmptyStateView(
                    icon: "photo.on.rectangle.angled",
                    title: "아직 사진이 없어요",
                    message: "이 컬렉션 미션이 나오는 날 사진을 찍으면 여기에 모여요."
                )
            } else {
                LazyVGrid(columns: columns, spacing: AppSpacing.gridGutter) {
                    ForEach(entries) { entry in
                        MissionPhotoTile(collection: collection, entry: entry)
                            .contextMenu {
                                Button("사진 삭제", systemImage: "trash", role: .destructive) {
                                    entryPendingDeletion = entry
                                }
                            }
                    }
                }
            }
        }
    }
}

// MARK: - Mission Photo Tile

private struct MissionPhotoTile: View {

    let collection: PhotoCollection
    let entry: MissionEntry

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M.d"
        return formatter.string(from: entry.missionDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            MissionPhotoImage(fileName: entry.imageFileName)
                .aspectRatio(1, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .background(collection.themeColor, in: RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))

            Text(dateLabel)
                .font(AppFont.caption2)
                .foregroundStyle(AppColor.Text.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        CollectionDetailView(collection: PhotoCollection.builtIn[0])
    }
    .environment(CollectionStore())
}
