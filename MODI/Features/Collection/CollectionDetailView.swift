import SwiftData
import SwiftUI

// MARK: - Editor Presentation

private struct CollectionEditorPresentation: Identifiable {
    let id = UUID()
    let image: UIImage
    var existingRecord: MODIRecord?
}

struct CollectionDetailView: View {

    @Environment(CollectionRepository.self) private var collectionRepository
    @Environment(RecordRepository.self) private var repository
    @Environment(StreakManager.self) private var streakManager
    @Environment(TitleCelebrationManager.self) private var titleCelebrationManager

    private let photoCollection: PhotoCollection?
    private let modiCollection: MODICollection?

    @State private var recordPendingDeletion: MODIRecord?
    @State private var editorPresentation: CollectionEditorPresentation?
    @State private var sharePayload: ShareImagePayload?

    init(collection: MODICollection) {
        self.modiCollection = collection
        self.photoCollection = nil
    }

    init(collection: PhotoCollection) {
        self.photoCollection = collection
        self.modiCollection = nil
    }

    private var collection: MODICollection {
        if let modiCollection {
            return modiCollection
        }

        if let photoCollection {
            return collectionRepository.collection(for: photoCollection.id)
                ?? MODICollection.from(
                    photoCollection: photoCollection,
                    type: photoCollection.category == .custom ? .custom : .system
                )
        }

        fatalError("CollectionDetailView requires a collection")
    }

    private var records: [MODIRecord] {
        repository.fetchRecords(for: collection)
    }

    private var progress: CollectionProgress {
        CollectionProgress.make(conceptID: collection.id, totalDiscoveries: records.count)
    }

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: AppSpacing.gridGutter),
        count: 3
    )

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
        .toolbarBackground(AppColor.Background.primary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    presentShareSheet()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                }
                .accessibilityLabel("공유하기")
            }
        }
        .fullScreenCover(item: $editorPresentation) { presentation in
            PhotoEditorView(
                image: presentation.image,
                concept: collection.concept,
                collection: collection,
                existingRecord: presentation.existingRecord
            ) {}
            .environment(repository)
            .environment(collectionRepository)
            .environment(streakManager)
            .environment(titleCelebrationManager)
        }
        .alert("이 사진을 삭제할까요?", isPresented: deletionAlertIsPresented, presenting: recordPendingDeletion) { record in
            Button("삭제", role: .destructive) {
                repository.deleteRecord(record)
                collectionRepository.reload()
                streakManager.refresh(
                    recordRepository: repository,
                    collectionRepository: collectionRepository
                )
                recordPendingDeletion = nil
            }
            Button("취소", role: .cancel) {
                recordPendingDeletion = nil
            }
        } message: { _ in
            Text("삭제한 사진은 복구할 수 없어요.")
        }
        .sheet(item: $sharePayload) { payload in
            CollectionShareOptionsSheet(image: payload.image)
                .presentationDetents([.medium, .large])
        }
    }

    private var deletionAlertIsPresented: Binding<Bool> {
        Binding(
            get: { recordPendingDeletion != nil },
            set: { if !$0 { recordPendingDeletion = nil } }
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

                    Text(collection.collectionDescription)
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                }
            }

            Text("\(discoveryCountLabel) · \(records.count)장의 사진")
                .font(AppFont.caption1)
                .foregroundStyle(AppColor.Text.tertiary)
        }
    }

    private var discoveryCountLabel: String {
        progress.totalDiscoveries == 1 ? "1 Discovery" : "\(progress.totalDiscoveries) Discoveries"
    }

    private var nextStageHint: String? {
        guard let until = progress.discoveriesUntilNext,
              let nextMilestone = progress.nextMilestone,
              let nextTitleName = ConceptTitleRegistry.title(for: collection.id, milestone: nextMilestone)?.name
        else {
            return records.isEmpty ? nil : "기록은 계속 이어져요"
        }

        if progress.currentTitle == nil {
            return "\(until)개의 발견이 모이면 \(nextTitleName)"
        }

        return "\(until)개 더 기록하면 \(nextTitleName)"
    }

    private var nextStageEmoji: String {
        if progress.nextMilestone == nil, !records.isEmpty {
            return collection.emoji
        }
        return ProgressMilestone.hintEmoji(for: progress.nextMilestone)
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if records.isEmpty {
                EmptyStateView(
                    icon: "photo.on.rectangle.angled",
                    title: "아직 사진이 없어요",
                    message: "이 컬렉션 Concept로 사진을 찍으면 여기에 모여요."
                )
            } else {
                LazyVGrid(columns: columns, spacing: AppSpacing.gridGutter) {
                    ForEach(records, id: \.id) { record in
                        NavigationLink(value: RecordNavigationValue(id: record.id)) {
                            MODIRecordTile(collection: collection, record: record)
                        }
                        .buttonStyle(.plain)
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

                nextStageHintSection
            }
        }
    }

    @ViewBuilder
    private var nextStageHintSection: some View {
        if let hint = nextStageHint {
            VStack(spacing: AppSpacing.sm) {
                Text(nextStageEmoji)
                    .font(.system(size: 28))

                if let titleName = progress.currentTitle?.name {
                    Text(titleName)
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                }

                Text(hint)
                    .font(AppFont.caption1)
                    .foregroundStyle(AppColor.Text.tertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.xl)
            .padding(.bottom, AppSpacing.sm)
        }
    }

    private func presentEditor(for record: MODIRecord) {
        guard let image = record.editingImage else { return }
        editorPresentation = CollectionEditorPresentation(
            image: image,
            existingRecord: record
        )
    }

    private func presentShareSheet() {
        guard let image = CollectionShareCardView.renderedImage(
            for: collection,
            records: records
        ) else { return }

        sharePayload = ShareImagePayload(image: image)
    }
}

// MARK: - MODI Record Tile

private struct MODIRecordTile: View {

    let collection: MODICollection
    let record: MODIRecord

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .background(collection.themeColor)
            .overlay {
                MODIRecordImage(record: record, contentMode: .fill)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
    }
}

#Preview("Light") {
    let (container, repository) = RecordPreviewData.makeRepository(
        withSampleData: true,
        sampleDiscoveryCount: 12
    )
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()
    let collection = collectionRepository.collection(for: Concept.mock.id)!

    return NavigationStack {
        CollectionDetailView(collection: collection)
    }
    .modelContainer(container)
    .environment(repository)
    .environment(collectionRepository)
    .environment(StreakManager.mock)
    .environment(TitleCelebrationManager())
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    let (container, repository) = RecordPreviewData.makeRepository(
        withSampleData: true,
        sampleDiscoveryCount: 12
    )
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()
    let collection = collectionRepository.collection(for: Concept.mock.id)!

    return NavigationStack {
        CollectionDetailView(collection: collection)
    }
    .modelContainer(container)
    .environment(repository)
    .environment(collectionRepository)
    .environment(StreakManager.mock)
    .environment(TitleCelebrationManager())
    .preferredColorScheme(.dark)
}

#Preview("Celebration") {
    let (container, repository) = RecordPreviewData.makeRepository(
        withSampleData: true,
        sampleDiscoveryCount: 30
    )
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()
    let collection = collectionRepository.collection(for: Concept.mock.id)!

    return NavigationStack {
        CollectionDetailView(collection: collection)
    }
    .modelContainer(container)
    .environment(repository)
    .environment(collectionRepository)
    .environment(StreakManager.mock)
    .environment(TitleCelebrationManager.mock)
    .preferredColorScheme(.light)
}
