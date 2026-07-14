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
    @Environment(PremiumManager.self) private var premiumManager

    private let photoCollection: PhotoCollection?
    private let modiCollection: MODICollection?

    @State private var recordPendingDeletion: MODIRecord?
    @State private var editorPresentation: CollectionEditorPresentation?
    @State private var sharePayload: CollectionSharePayload?
    @State private var shareErrorMessage: String?
    @State private var deleteErrorMessage: String?
    @State private var recordContextMenuTracker = ContextMenuVisibilityTracker<UUID>()
    @State private var selectedRecordID: UUID?

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

    private var selectedRecord: MODIRecord? {
        if let selectedRecordID,
           let record = records.first(where: { $0.id == selectedRecordID }) {
            return record
        }

        return records.first
    }

    private var progress: CollectionProgress {
        CollectionProgress.make(conceptID: collection.id, totalDiscoveries: records.count)
    }

    private var isFreeCustomSlot: Bool {
        guard collection.collectionType == .custom else { return false }
        return premiumManager.freeCustomCollectionSlotID(in: collectionRepository.collections) == collection.id
    }

    private var isPremiumCustomSlot: Bool {
        collection.collectionType == .custom && !isFreeCustomSlot
    }

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var columns: [GridItem] {
        if isPad {
            return [
                GridItem(.adaptive(minimum: 92, maximum: 132), spacing: AppSpacing.md)
            ]
        }

        return Array(
            repeating: GridItem(.flexible(), spacing: AppSpacing.gridGutter),
            count: 3
        )
    }

    var body: some View {
        Group {
            if isPad {
                iPadDetailContent
            } else {
                iPhoneDetailContent
            }
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
                        .font(.system(size: 17, weight: .semibold))
                }
                .accessibilityLabel("공유하기")
            }
        }
        .onAppear {
            syncSelectedRecord()
        }
        .onChange(of: records.count) {
            syncSelectedRecord()
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

    private var iPhoneDetailContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                headerSection
                photosSection
            }
            .appScreenPadding()
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxxl)
        }
    }

    private var iPadDetailContent: some View {
        HStack(alignment: .top, spacing: AppSpacing.huge) {
            featuredPhotoPane

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    headerSection
                    selectedRecordInfoSection
                    photosSection
                }
                .padding(.vertical, AppSpacing.xxl)
                .padding(.trailing, AppSpacing.huge)
            }
            .frame(width: 380)
        }
        .padding(.leading, AppSpacing.huge)
    }

    @ViewBuilder
    private var featuredPhotoPane: some View {
        if let selectedRecord {
            MODIRecordImage(record: selectedRecord, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(AppSpacing.xxl)
                .background(AppColor.Background.secondary, in: RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous))
                .appShadow(.medium)
                .padding(.vertical, AppSpacing.xxl)
        } else {
            EmptyStateView(
                icon: "photo.on.rectangle.angled",
                title: "아직 사진이 없어요",
                message: "이 컬렉션 Concept로 사진을 찍으면 여기에 모여요."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, AppSpacing.xxl)
        }
    }

    @ViewBuilder
    private var selectedRecordInfoSection: some View {
        if let selectedRecord {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("기록 정보")
                        .font(AppFont.title3)
                        .foregroundStyle(AppColor.Text.primary)

                    Text(selectedRecord.discoveryDateLabel)
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                }

                if selectedRecord.userWrittenTexts.isEmpty {
                    Text("아직 남긴 메모가 없어요.")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.Text.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appCardStyle()
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        ForEach(selectedRecord.userWrittenTexts, id: \.self) { text in
                            Text(text)
                                .font(AppFont.body)
                                .foregroundStyle(AppColor.Text.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .appCardStyle()
                }

                Button {
                    presentEditor(for: selectedRecord)
                } label: {
                    Label("편집하기", systemImage: "wand.and.stars")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
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

            if isFreeCustomSlot {
                Text("기본 슬롯")
                    .font(AppFont.caption1)
                    .foregroundStyle(AppColor.Text.primary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(AppColor.Background.secondary, in: Capsule())
            } else if isPremiumCustomSlot {
                Text("MODI+")
                    .font(AppFont.caption1.weight(.semibold))
                    .foregroundStyle(AppColor.Semantic.warning)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(AppColor.Semantic.warning.opacity(0.12), in: Capsule())
            }
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
            return "\(until)개의 발견이 모이면 \(nextTitleName) 배너"
        }

        return "\(until)개 더 기록하면 \(nextTitleName) 배너"
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
                LazyVGrid(columns: columns, spacing: isPad ? AppSpacing.md : AppSpacing.gridGutter) {
                    ForEach(records, id: \.id) { record in
                        recordThumbnail(record)
                        .background {
                            Color.clear
                                .contextMenu {
                                    Button {
                                        performRecordContextMenuAction(from: record.id) {
                                            presentEditor(for: record)
                                        }
                                    } label: {
                                        recordContextMenuLabel("사진 수정", systemImage: "pencil", recordID: record.id)
                                    }
                                    Button(role: .destructive) {
                                        performRecordContextMenuAction(from: record.id) {
                                            recordPendingDeletion = record
                                        }
                                    } label: {
                                        recordContextMenuLabel("사진 삭제", systemImage: "trash", recordID: record.id)
                                    }
                                }
                                .id(record.id)
                        }
                    }
                }

                nextStageHintSection
            }
        }
    }

    @ViewBuilder
    private func recordThumbnail(_ record: MODIRecord) -> some View {
        if isPad {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedRecordID = record.id
                }
            } label: {
                MODIRecordTile(collection: collection, record: record)
                    .overlay {
                        if selectedRecord?.id == record.id {
                            RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                                .strokeBorder(AppColor.Accent.highlight, lineWidth: 3)
                        }
                    }
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
        } else {
            NavigationLink(value: RecordNavigationValue(id: record.id)) {
                MODIRecordTile(collection: collection, record: record)
            }
            .buttonStyle(.plain)
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

    private func syncSelectedRecord() {
        if selectedRecordID == nil {
            selectedRecordID = records.first?.id
            return
        }

        guard let selectedRecordID else { return }
        if !records.contains(where: { $0.id == selectedRecordID }) {
            self.selectedRecordID = records.first?.id
        }
    }

    private func performRecordContextMenuAction(
        from recordID: UUID,
        _ action: @escaping @MainActor () -> Void
    ) {
        guard recordContextMenuTracker.allowsAction(from: recordID) else { return }

        Task { @MainActor in
            // Let UIKit finish dismissing the context menu before SwiftUI presents navigation or alerts.
            try? await Task.sleep(for: .milliseconds(150))
            action()
        }
    }

    private func recordContextMenuLabel(
        _ title: String,
        systemImage: String,
        recordID: UUID
    ) -> some View {
        Label(title, systemImage: systemImage)
            .onAppear {
                recordContextMenuTracker.markVisible(recordID)
            }
            .onDisappear {
                recordContextMenuTracker.markHidden(recordID)
            }
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
        HapticManager.shared.warning()

        do {
            try await deleteRemoteRecordIfNeeded(record)
            repository.deleteRecord(record)
            collectionRepository.reload()
            streakManager.refresh(
                recordRepository: repository,
                collectionRepository: collectionRepository
            )
            recordPendingDeletion = nil
            ToastManager.shared.showRecordDeleted()
        } catch {
            deleteErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func deleteRemoteRecordIfNeeded(_ record: MODIRecord) async throws {
        guard authManager.session.isLoggedIn,
              let accessToken = authManager.accessToken
        else { return }

        let remoteRecordID = try await resolveRemoteRecordID(for: record, accessToken: accessToken)
        try await RecordsAPIService.shared.deleteMyRecord(
            recordId: remoteRecordID,
            accessToken: accessToken
        )
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

#Preview("Custom Collection") {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let schema = Schema([MODIRecord.self, MODICollection.self])
    let container = try! ModelContainer(for: schema, configurations: configuration)
    let collectionRepository = CollectionPreviewData.makeRepository(
        modelContext: container.mainContext,
        withSampleData: true
    )
    let repository = RecordRepository(modelContext: container.mainContext)
    let collection = collectionRepository.customCollections[0]

    return NavigationStack {
        CollectionDetailView(collection: collection)
    }
    .modelContainer(container)
    .environment(repository)
    .environment(collectionRepository)
    .environment(StreakManager.mock)
    .environment(TitleCelebrationManager())
    .environment(AuthManager.mock)
    .environment(PremiumManager.shared)
    .preferredColorScheme(.light)
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
    .environment(PremiumManager.shared)
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
    .environment(PremiumManager.shared)
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
    .environment(PremiumManager.shared)
    .preferredColorScheme(.light)
}
