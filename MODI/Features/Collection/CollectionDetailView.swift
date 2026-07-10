import SwiftData
import SwiftUI

// MARK: - Editor Presentation

private struct CollectionEditorPresentation: Identifiable {
    let id = UUID()
    let image: UIImage
    var existingRecord: MODIRecord?
}

struct CollectionDetailView: View {

    @Environment(AuthManager.self) private var authManager
    @Environment(CollectionRepository.self) private var collectionRepository
    @Environment(RecordRepository.self) private var repository
    @Environment(StreakManager.self) private var streakManager
    @Environment(TitleCelebrationManager.self) private var titleCelebrationManager

    private let photoCollection: PhotoCollection?
    private let modiCollection: MODICollection?

    @State private var recordPendingDeletion: MODIRecord?
    @State private var editorPresentation: CollectionEditorPresentation?
    @State private var sharePayload: CollectionSharePayload?
    @State private var shareErrorMessage: String?
    @State private var deleteErrorMessage: String?

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
                Task {
                    await deleteRecord(record)
                }
            }
            Button("취소", role: .cancel) {
                recordPendingDeletion = nil
            }
        } message: { _ in
            Text("삭제한 사진은 복구할 수 없어요.")
        }
        .alert("삭제 실패", isPresented: deleteFailedAlertIsPresented) {
            Button("확인", role: .cancel) {
                deleteErrorMessage = nil
            }
        } message: {
            Text(deleteErrorMessage ?? "사진을 삭제하지 못했어요.")
        }
        .sheet(item: $sharePayload) { payload in
            CollectionShareOptionsSheet(
                collection: payload.collection,
                records: payload.records
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .alert("공유할 수 없어요", isPresented: shareErrorAlertIsPresented) {
            Button("확인", role: .cancel) {
                shareErrorMessage = nil
            }
        } message: {
            Text(shareErrorMessage ?? "공유를 준비하지 못했어요.")
        }
    }

    private var deletionAlertIsPresented: Binding<Bool> {
        Binding(
            get: { recordPendingDeletion != nil },
            set: { if !$0 { recordPendingDeletion = nil } }
        )
    }

    private var deleteFailedAlertIsPresented: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )
    }

    private var shareErrorAlertIsPresented: Binding<Bool> {
        Binding(
            get: { shareErrorMessage != nil },
            set: { if !$0 { shareErrorMessage = nil } }
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
        guard !records.isEmpty else {
            shareErrorMessage = "공유할 사진이 없어요."
            return
        }

        sharePayload = CollectionSharePayload(
            collection: collection,
            records: records
        )
    }

    private func deleteRecord(_ record: MODIRecord) async {
        do {
            if authManager.session.isLoggedIn,
               let accessToken = authManager.accessToken {
                let remoteRecordID = try await resolveRemoteRecordID(for: record, accessToken: accessToken)
                try await RecordsAPIService.shared.deleteMyRecord(
                    recordId: remoteRecordID,
                    accessToken: accessToken
                )
            }

            repository.deleteRecord(record)
            collectionRepository.reload()
            streakManager.refresh(
                recordRepository: repository,
                collectionRepository: collectionRepository
            )
            recordPendingDeletion = nil
        } catch {
            deleteErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func resolveRemoteRecordID(for record: MODIRecord, accessToken: String) async throws -> String {
        if let serverId = record.serverId {
            return serverId
        }

        // Legacy local rows may not have serverId. Find the matching server row by recordDate.
        let serverRecords = try await RecordsAPIService.shared.fetchMyRecords(accessToken: accessToken)
        let calendar = Calendar(identifier: .gregorian)
        if let matched = serverRecords.first(where: {
            calendar.isDate($0.recordDate, inSameDayAs: record.discoveryDate)
        }) {
            repository.updateServerID(for: record, serverID: matched.id)
            return matched.id
        }

        return record.id.uuidString
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
            .modiRecordClipShape(for: record)
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
    .environment(AuthManager.mock)
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
    .environment(AuthManager.mock)
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
    .environment(AuthManager.mock)
    .preferredColorScheme(.light)
}
