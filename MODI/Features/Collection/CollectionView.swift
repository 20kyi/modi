import SwiftData
import SwiftUI

struct CollectionView: View {

    @Environment(AuthManager.self) private var authManager
    @Environment(CollectionStore.self) private var store
    @Environment(RecordRepository.self) private var repository
    @Environment(CollectionRepository.self) private var collectionRepository
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(StreakManager.self) private var streakManager

    @State private var isShowingAddCollection = false
    @State private var isShowingCollectionLimitSheet = false
    @State private var isShowingPremium = false
    @State private var pickerAction: CustomCollectionPickerAction?
    @State private var isShowingEditCollection = false
    @State private var editingCollectionID: UUID?
    @State private var collectionPendingDeletion: MODICollection?
    @State private var deleteErrorMessage: String?
    @State private var collectionContextMenuTracker = ContextMenuVisibilityTracker<UUID>()

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.gridGutter),
        GridItem(.flexible(), spacing: AppSpacing.gridGutter)
    ]

    private struct CollectionContextMenuState {
        let collectionID: UUID
        let canDelete: Bool
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                    headerSection

                    ForEach(visibleCategories) { category in
                        categorySection(category)
                    }
                }
                .appScreenPadding()
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxxl)
            }
            .appScreenBackground()
            .navigationTitle("컬렉션")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.Background.primary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            attemptCreateCustomCollection()
                        } label: {
                            Label("컬렉션 추가", systemImage: "plus")
                        }

                        Button {
                            pickerAction = .edit
                        } label: {
                            Label("컬렉션 수정", systemImage: "pencil")
                        }
                        .disabled(editableCollections.isEmpty)

                        Button(role: .destructive) {
                            pickerAction = .delete
                        } label: {
                            Label("컬렉션 삭제", systemImage: "trash")
                        }
                        .disabled(customCollections.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .accessibilityLabel("컬렉션 관리")
                }
            }
            .navigationDestination(isPresented: $isShowingAddCollection) {
                AddCollectionView()
            }
            .navigationDestination(isPresented: $isShowingEditCollection) {
                if let editingCollectionID,
                   let collection = collectionRepository.collection(for: editingCollectionID) {
                    AddCollectionView(editingCollection: collection)
                }
            }
            .navigationDestination(isPresented: $isShowingPremium) {
                PremiumView()
            }
            .sheet(isPresented: $isShowingCollectionLimitSheet) {
                CustomCollectionLimitSheet(
                    onShowPremium: {
                        isShowingCollectionLimitSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            isShowingPremium = true
                        }
                    }
                )
            }
            .sheet(item: $pickerAction) { action in
                CustomCollectionPickerSheet(
                    action: action,
                    collections: collections(for: action),
                    photoCount: { collectionRepository.photoCount(for: $0) },
                    onSelect: { collection in
                        pickerAction = nil
                        handleCustomCollectionSelection(collection, action: action)
                    }
                )
            }
            .alert("이 컬렉션을 삭제할까요?", isPresented: deleteCollectionAlertIsPresented, presenting: collectionPendingDeletion) { collection in
                Button("삭제", role: .destructive) {
                    Task {
                        await deleteCollection(collection)
                    }
                }
                Button("취소", role: .cancel) {
                    collectionPendingDeletion = nil
                }
            } message: { collection in
                let count = collectionRepository.photoCount(for: collection.id)
                if count == 0 {
                    Text("삭제한 컬렉션은 복구할 수 없어요.")
                } else {
                    Text("컬렉션과 함께 \(count)장의 사진도 모두 삭제돼요. 복구할 수 없어요.")
                }
            }
            .alert("삭제 실패", isPresented: deleteFailedAlertIsPresented) {
                Button("확인", role: .cancel) {
                    deleteErrorMessage = nil
                }
            } message: {
                Text(deleteErrorMessage ?? "컬렉션을 삭제하지 못했어요.")
            }
            .navigationDestination(for: PhotoCollection.self) { collection in
                CollectionDetailView(collection: collection)
            }
            .navigationDestination(for: RecordNavigationValue.self) { navigationValue in
                if let record = repository.records.first(where: { $0.id == navigationValue.id }) {
                    if let collection = record.collection ?? collectionRepository.collection(for: record.conceptId) {
                        RecordDetailView(record: record, collection: collection)
                    } else {
                        EmptyView()
                    }
                } else {
                    EmptyView()
                }
            }
        }
    }

    private var visibleCategories: [CollectionCategory] {
        [.color, .nature, .custom]
    }

    private var customCollections: [MODICollection] {
        collectionRepository.customCollections
    }

    private var editableCollections: [MODICollection] {
        let categoryOrder: [CollectionCategory: Int] = [.color: 0, .nature: 1, .custom: 2]
        return collectionRepository.collections.sorted { lhs, rhs in
            let lhsOrder = categoryOrder[lhs.collectionCategory] ?? Int.max
            let rhsOrder = categoryOrder[rhs.collectionCategory] ?? Int.max
            if lhsOrder != rhsOrder { return lhsOrder < rhsOrder }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    private var freeCustomSlotID: UUID? {
        premiumManager.freeCustomCollectionSlotID(in: collectionRepository.collections)
    }

    private func slotBadge(for collection: PhotoCollection, in category: CollectionCategory) -> CollectionCard.SlotBadge {
        guard category == .custom else { return .none }
        guard let freeCustomSlotID else { return .none }
        return collection.id == freeCustomSlotID ? .basic : .premium
    }

    private var deleteCollectionAlertIsPresented: Binding<Bool> {
        Binding(
            get: { collectionPendingDeletion != nil },
            set: { if !$0 { collectionPendingDeletion = nil } }
        )
    }

    private var deleteFailedAlertIsPresented: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )
    }

    private func handleCustomCollectionSelection(
        _ collection: MODICollection,
        action: CustomCollectionPickerAction
    ) {
        switch action {
        case .edit:
            editingCollectionID = collection.id
            isShowingEditCollection = true
        case .delete:
            collectionPendingDeletion = collection
        }
    }

    private func handleCustomCollectionSelection(
        collectionID: UUID,
        action: CustomCollectionPickerAction
    ) {
        guard let collection = collectionRepository.collection(for: collectionID) else { return }
        handleCustomCollectionSelection(collection, action: action)
    }

    private func collections(for action: CustomCollectionPickerAction) -> [MODICollection] {
        switch action {
        case .edit:
            editableCollections
        case .delete:
            customCollections
        }
    }

    private func attemptCreateCustomCollection() {
        if premiumManager.canCreateCustomCollection(in: collectionRepository.collections) {
            isShowingAddCollection = true
        } else {
            isShowingCollectionLimitSheet = true
        }
    }

    private func collectionContextMenuState(for collection: PhotoCollection) -> CollectionContextMenuState? {
        guard let modiCollection = collectionRepository.collection(for: collection.id) else { return nil }

        return CollectionContextMenuState(
            collectionID: modiCollection.id,
            canDelete: modiCollection.collectionType == .custom
        )
    }

    private func performCollectionContextMenuAction(
        from collectionID: UUID,
        _ action: @escaping @MainActor () -> Void
    ) {
        guard collectionContextMenuTracker.allowsAction(from: collectionID) else { return }

        Task { @MainActor in
            // Let UIKit finish dismissing the context menu before SwiftUI presents navigation or alerts.
            try? await Task.sleep(for: .milliseconds(150))
            action()
        }
    }

    private func deleteCollection(_ collection: MODICollection) async {
        HapticManager.shared.warning()

        do {
            let records = repository.fetchRecords(for: collection)

            for record in records {
                try await deleteRemoteRecordIfNeeded(record)
            }

            collectionRepository.deleteCustomCollection(
                collection,
                accessToken: authManager.accessToken
            )
            repository.reload()
            streakManager.refresh(
                recordRepository: repository,
                collectionRepository: collectionRepository
            )
            collectionPendingDeletion = nil
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

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("미션별로 사진이 모여요")
                .font(AppFont.title2)
                .foregroundStyle(AppColor.Text.primary)

            Text("매일 다른 미션을 수행하면 해당 컬렉션에 사진이 쌓입니다.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.Text.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func categorySection(_ category: CollectionCategory) -> some View {
        let collections = PhotoCollection.collections(in: category, custom: store.customCollections)

        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text(category.displayName)
                    .font(AppFont.title3)
                    .foregroundStyle(AppColor.Text.primary)

                if category == .custom {
                    Spacer()
                    Button(action: attemptCreateCustomCollection) {
                        Label("추가", systemImage: "plus.circle")
                            .font(AppFont.footnote)
                            .foregroundStyle(AppColor.Accent.highlight)
                    }
                }
            }

            if collections.isEmpty {
                Button(action: attemptCreateCustomCollection) {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppColor.Accent.highlight)

                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text("첫 커스텀 컬렉션 만들기")
                                .font(AppFont.subheadline)
                                .foregroundStyle(AppColor.Text.primary)

                            Text("나만의 미션을 추가해보세요")
                                .font(AppFont.caption1)
                                .foregroundStyle(AppColor.Text.secondary)
                        }

                        Spacer()
                    }
                    .appCardStyle()
                }
                .buttonStyle(.plain)
            } else {
                LazyVGrid(columns: columns, spacing: AppSpacing.gridGutter) {
                    ForEach(collections) { collection in
                        let menuState = collectionContextMenuState(for: collection)

                        NavigationLink(value: collection) {
                            CollectionCard(
                                collection: collection,
                                photoCount: repository.photoCount(for: collection.id),
                                slotBadge: slotBadge(for: collection, in: category)
                            )
                        }
                        .buttonStyle(.plain)
                        .background {
                            if let menuState {
                                Color.clear
                                    .contextMenu {
                                        collectionContextMenu(menuState)
                                    }
                                    .id(menuState.collectionID)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func collectionContextMenu(_ menuState: CollectionContextMenuState) -> some View {
        Button {
            performCollectionContextMenuAction(from: menuState.collectionID) {
                handleCustomCollectionSelection(collectionID: menuState.collectionID, action: .edit)
            }
        } label: {
            collectionContextMenuLabel("수정", systemImage: "pencil", collectionID: menuState.collectionID)
        }

        if menuState.canDelete {
            Button(role: .destructive) {
                performCollectionContextMenuAction(from: menuState.collectionID) {
                    handleCustomCollectionSelection(collectionID: menuState.collectionID, action: .delete)
                }
            } label: {
                collectionContextMenuLabel("삭제", systemImage: "trash", collectionID: menuState.collectionID)
            }
        }
    }

    private func collectionContextMenuLabel(
        _ title: String,
        systemImage: String,
        collectionID: UUID
    ) -> some View {
        Label(title, systemImage: systemImage)
            .onAppear {
                collectionContextMenuTracker.markVisible(collectionID)
            }
            .onDisappear {
                collectionContextMenuTracker.markHidden(collectionID)
            }
    }
}

@MainActor
final class ContextMenuVisibilityTracker<ID: Hashable> {

    private var visibleCounts: [ID: Int] = [:]
    private var lastHiddenAt: [ID: Date] = [:]
    private let hiddenActionGraceInterval: TimeInterval

    init(hiddenActionGraceInterval: TimeInterval = 0.35) {
        self.hiddenActionGraceInterval = hiddenActionGraceInterval
    }

    func markVisible(_ id: ID) {
        visibleCounts[id, default: 0] += 1
        lastHiddenAt[id] = nil
    }

    func markHidden(_ id: ID) {
        let remainingVisibleCount = max((visibleCounts[id] ?? 0) - 1, 0)

        if remainingVisibleCount == 0 {
            visibleCounts[id] = nil
            lastHiddenAt[id] = Date()
        } else {
            visibleCounts[id] = remainingVisibleCount
        }
    }

    func isVisible(_ id: ID) -> Bool {
        (visibleCounts[id] ?? 0) > 0
    }

    func allowsAction(from id: ID) -> Bool {
        if isVisible(id) {
            return true
        }

        guard let hiddenAt = lastHiddenAt[id] else {
            return false
        }

        return Date().timeIntervalSince(hiddenAt) <= hiddenActionGraceInterval
    }
}

#Preview("Light") {
    let (container, repository) = RecordPreviewData.makeRepository(withSampleData: true, sampleDiscoveryCount: 12)
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()
    return CollectionView()
        .modelContainer(container)
        .environment(CollectionStore())
        .environment(repository)
        .environment(collectionRepository)
        .environment(TitleCelebrationManager())
        .environment(PremiumManager.shared)
        .environment(AuthManager.mock)
        .environment(StreakManager())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    let (container, repository) = RecordPreviewData.makeRepository(withSampleData: true, sampleDiscoveryCount: 12)
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()
    return CollectionView()
        .modelContainer(container)
        .environment(CollectionStore())
        .environment(repository)
        .environment(collectionRepository)
        .environment(TitleCelebrationManager())
        .environment(PremiumManager.shared)
        .environment(AuthManager.mock)
        .environment(StreakManager())
        .preferredColorScheme(.dark)
}
