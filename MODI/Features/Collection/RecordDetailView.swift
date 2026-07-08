import SwiftData
import SwiftUI

// MARK: - Editor Presentation

private struct RecordEditorPresentation: Identifiable {
    let id = UUID()
    let image: UIImage
    let record: MODIRecord
}

struct RecordDetailView: View {

    @Environment(CollectionRepository.self) private var collectionRepository
    @Environment(RecordRepository.self) private var repository
    @Environment(StreakManager.self) private var streakManager
    @Environment(\.dismiss) private var dismiss

    let record: MODIRecord
    let collection: MODICollection

    @State private var showDeleteAlert = false
    @State private var editorPresentation: RecordEditorPresentation?

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: record.createdAt)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                recordPhoto
                infoCard
                actionButtons
            }
            .appScreenPadding()
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .appScreenBackground()
        .navigationTitle("기록 상세")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $editorPresentation) { presentation in
            PhotoEditorView(
                image: presentation.image,
                concept: collection.concept,
                collection: collection,
                existingRecord: presentation.record
            ) {}
            .environment(repository)
            .environment(collectionRepository)
            .environment(streakManager)
        }
        .alert("이 사진을 삭제할까요?", isPresented: $showDeleteAlert) {
            Button("삭제", role: .destructive) {
                repository.deleteRecord(record)
                collectionRepository.reload()
                streakManager.refresh(
                    recordRepository: repository,
                    collectionRepository: collectionRepository
                )
                dismiss()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("삭제한 사진은 복구할 수 없어요.")
        }
    }

    private var recordPhoto: some View {
        HStack {
            Spacer(minLength: 0)

            RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                .fill(AppColor.Background.secondary)
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .frame(maxWidth: 300)
                .overlay {
                    MODIRecordImage(record: record, contentMode: .fill)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
                .appShadow(.medium)

            Spacer(minLength: 0)
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                Text(collection.emoji)
                    .font(.system(size: 32))
                    .frame(width: 52, height: 52)
                    .background(collection.themeColor, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(collection.title)
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.Text.primary)

                    Text(dateLabel)
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                }
            }

            if record.wasEdited {
                Label("꾸민 사진", systemImage: "wand.and.stars")
                    .font(AppFont.caption1)
                    .foregroundStyle(AppColor.Accent.primary)
            }
        }
        .appCardStyle()
    }

    private var actionButtons: some View {
        VStack(spacing: AppSpacing.md) {
            Button {
                presentEditor()
            } label: {
                Label("사진 수정", systemImage: "pencil")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("사진 삭제", role: .destructive) {
                showDeleteAlert = true
            }
            .font(AppFont.footnote)
        }
    }

    private func presentEditor() {
        guard let image = record.editingImage else { return }
        editorPresentation = RecordEditorPresentation(image: image, record: record)
    }
}

// MARK: - Navigation

struct RecordNavigationValue: Hashable {
    let id: UUID
}

#Preview {
    let (container, repository) = RecordPreviewData.makeRepository(withSampleData: true)
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()
    let collection = collectionRepository.collection(for: Concept.mock.id)!
    let record = repository.fetchRecords(for: collection)[0]

    return NavigationStack {
        RecordDetailView(record: record, collection: collection)
    }
    .modelContainer(container)
    .environment(repository)
    .environment(collectionRepository)
    .environment(StreakManager.mock)
}
