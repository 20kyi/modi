import SwiftData
import SwiftUI

// MARK: - Editor Presentation

private struct CollectionEditorPresentation: Identifiable {
    let id = UUID()
    let image: UIImage
    var existingRecord: MODIRecord?
}

struct CollectionDetailView: View {

    @Environment(MODIRepository.self) private var repository

    let collection: PhotoCollection

    @State private var recordPendingDeletion: MODIRecord?
    @State private var showPhotoLibrary = false
    @State private var editorPresentation: CollectionEditorPresentation?

    private var records: [MODIRecord] {
        repository.fetchRecords(missionId: collection.id)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showPhotoLibrary = true
                } label: {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                }
                .accessibilityLabel("앨범에서 사진 추가")
            }
        }
        .sheet(isPresented: $showPhotoLibrary) {
            AlbumPhotoPickerSheet { image in
                showPhotoLibrary = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    editorPresentation = CollectionEditorPresentation(image: image)
                }
            }
        }
        .fullScreenCover(item: $editorPresentation) { presentation in
            PhotoEditorView(
                image: presentation.image,
                concept: conceptForCollection,
                existingRecord: presentation.existingRecord
            ) {}
        }
        .alert("이 사진을 삭제할까요?", isPresented: deletionAlertIsPresented, presenting: recordPendingDeletion) { record in
            Button("삭제", role: .destructive) {
                repository.deleteRecord(record)
                recordPendingDeletion = nil
            }
            Button("취소", role: .cancel) {
                recordPendingDeletion = nil
            }
        } message: { _ in
            Text("삭제한 사진은 복구할 수 없어요.")
        }
    }

    private var deletionAlertIsPresented: Binding<Bool> {
        Binding(
            get: { recordPendingDeletion != nil },
            set: { if !$0 { recordPendingDeletion = nil } }
        )
    }

    private var conceptForCollection: Concept {
        let type: ConceptType = collection.category == .custom ? .custom : .system
        return Concept(from: collection, type: type)
    }

    private func presentEditor(for record: MODIRecord) {
        guard let image = UIImage(data: record.imageData) else { return }
        editorPresentation = CollectionEditorPresentation(
            image: image,
            existingRecord: record
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

            Text("\(records.count)장의 사진")
                .font(AppFont.caption1)
                .foregroundStyle(AppColor.Text.tertiary)
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if records.isEmpty {
                EmptyStateView(
                    icon: "photo.on.rectangle.angled",
                    title: "아직 사진이 없어요",
                    message: "이 컬렉션 미션이 나오는 날 사진을 찍으면 여기에 모여요."
                )
            } else {
                LazyVGrid(columns: columns, spacing: AppSpacing.gridGutter) {
                    ForEach(records, id: \.id) { record in
                        MODIRecordTile(collection: collection, record: record)
                            .contextMenu {
                                Button("사진 수정", systemImage: "pencil") {
                                    presentEditor(for: record)
                                }
                                Button("사진 삭제", systemImage: "trash", role: .destructive) {
                                    recordPendingDeletion = record
                                }
                            }
                    }
                }
            }
        }
    }
}

// MARK: - MODI Record Tile

private struct MODIRecordTile: View {

    let collection: PhotoCollection
    let record: MODIRecord

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M.d"
        return formatter.string(from: record.createdAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            MODIRecordImage(record: record)
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
    let (container, repository) = MODIPreviewData.makeRepository(withSampleData: true)
    return NavigationStack {
        CollectionDetailView(collection: PhotoCollection.builtIn[6])
    }
    .modelContainer(container)
    .environment(repository)
}
