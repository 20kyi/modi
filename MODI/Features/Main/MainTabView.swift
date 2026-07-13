import SwiftData
import SwiftUI

// MARK: - Tab

enum MainTab: Hashable {
    case home
    case create
    case collection
    case profile
}

// MARK: - MainTabView

struct MainTabView: View {

    @Environment(AuthManager.self) private var authManager
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(MissionManager.self) private var missionManager
    @Environment(DeepLinkCoordinator.self) private var deepLinkCoordinator
    @State private var collectionStore = CollectionStore()
    @State private var repository: RecordRepository?
    @State private var collectionRepository: CollectionRepository?
    @State private var streakManager = StreakManager()
    @State private var titleCelebrationManager = TitleCelebrationManager()
    @State private var earnedTitleModalPresenter = EarnedTitleModalPresenter()
    @State private var selectedTab: MainTab = .home
    @State private var isBootstrapping = true
    @AppStorage("modi.openCollectionAfterInitialLoad") private var openCollectionAfterInitialLoad = false

    var body: some View {
        Group {
            if isBootstrapping {
                DataLoadingView()
                    .transition(.opacity)
            } else if let repository, let collectionRepository {
                tabView(repository: repository, collectionRepository: collectionRepository)
                    .transition(.opacity)
            }
        }
        .task {
            await performBootstrapIfNeeded()
        }
    }

    private func tabView(
        repository: RecordRepository,
        collectionRepository: CollectionRepository
    ) -> some View {
        @Bindable var celebrationManager = titleCelebrationManager
        @Bindable var earnedTitlePresenter = earnedTitleModalPresenter

        return TabView(selection: $selectedTab) {
            HomeView(
                missionManager: missionManager,
                onCreateTapped: { selectedTab = .create }
            )
            .tabItem {
                Label("홈", systemImage: "house.fill")
            }
            .tag(MainTab.home)

            CreateView()
                .tabItem {
                    Label("만들기", systemImage: "plus.circle.fill")
                }
                .tag(MainTab.create)

            CollectionView()
                .tabItem {
                    Label("컬렉션", systemImage: "square.grid.2x2.fill")
                }
                .tag(MainTab.collection)

            ProfileView()
                .tabItem {
                    Label("프로필", systemImage: "person.fill")
                }
                .tag(MainTab.profile)
        }
        .tint(AppColor.Accent.highlight)
        .toolbarBackground(AppColor.Background.primary, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .environment(collectionStore)
        .environment(missionManager)
        .environment(repository)
        .environment(collectionRepository)
        .environment(streakManager)
        .environment(titleCelebrationManager)
        .environment(earnedTitleModalPresenter)
        .overlay {
            if let presentation = earnedTitlePresenter.presentation {
                EarnedTitleDetailModal(earnedTitle: presentation.earnedTitle) {
                    earnedTitleModalPresenter.dismiss()
                }
                .id(presentation.id)
            }
        }
        .sheet(item: $celebrationManager.pendingCelebration) { celebration in
            TitleCelebrationSheet(
                celebration: celebration,
                onContinue: { titleCelebrationManager.dismiss() },
                onShare: { titleCelebrationManager.dismiss() }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task {
            if notificationManager.isEnabled {
                await notificationManager.scheduleDailyNotifications(missionManager: missionManager)
            }
        }
        .onAppear {
            syncWidgetData(repository: repository, collectionRepository: collectionRepository)
        }
        .onChange(of: repository.records.count) {
            syncWidgetData(repository: repository, collectionRepository: collectionRepository)
        }
        .onChange(of: authManager.session.isLoggedIn) { oldValue, newValue in
            if oldValue, !newValue {
                clearLocalUserDataIfNeeded(
                    repository: repository,
                    collectionRepository: collectionRepository
                )
                return
            }
            guard !oldValue, newValue else { return }

            Task {
                await loadLoggedInUserData(
                    repository: repository,
                    collectionRepository: collectionRepository,
                    navigateToCollection: true
                )
            }
        }
        .onChange(of: deepLinkCoordinator.pendingDestination) { _, destination in
            guard destination == .todayMission else { return }
            selectedTab = .home
        }
    }

    private func performBootstrapIfNeeded() async {
        guard repository == nil else {
            withAnimation(.easeInOut(duration: 0.35)) {
                isBootstrapping = false
            }
            return
        }

        let recordRepository = RecordRepository(modelContext: modelContext)
        let collectionRepo = CollectionRepository(modelContext: modelContext)
        collectionRepo.bootstrap()
        collectionStore.configure(collectionRepository: collectionRepo)
        missionManager.configure(collectionRepository: collectionRepo)
        repository = recordRepository
        collectionRepository = collectionRepo
        streakManager.refresh(
            recordRepository: recordRepository,
            collectionRepository: collectionRepo
        )

        if authManager.session.isLoggedIn {
            let shouldOpenCollection = openCollectionAfterInitialLoad
            await loadLoggedInUserData(
                repository: recordRepository,
                collectionRepository: collectionRepo,
                navigateToCollection: shouldOpenCollection
            )
            return
        }

        await missionManager.refreshSystemConcepts(accessToken: authManager.accessToken)

        withAnimation(.easeInOut(duration: 0.35)) {
            isBootstrapping = false
        }
    }

    private func loadLoggedInUserData(
        repository: RecordRepository,
        collectionRepository: CollectionRepository,
        navigateToCollection: Bool
    ) async {
        withAnimation(.easeInOut(duration: 0.35)) {
            isBootstrapping = true
        }

        await missionManager.refreshSystemConcepts(accessToken: authManager.accessToken)
        await syncCustomCollectionsFromServer(collectionRepository: collectionRepository)
        await syncRecordsFromServer(
            repository: repository,
            collectionRepository: collectionRepository
        )

        if navigateToCollection {
            openCollectionAfterInitialLoad = false
            withAnimation(.easeInOut(duration: 0.35)) {
                selectedTab = .collection
            }
        }

        withAnimation(.easeInOut(duration: 0.35)) {
            isBootstrapping = false
        }
    }

    private func syncWidgetData(
        repository: RecordRepository,
        collectionRepository: CollectionRepository
    ) {
        streakManager.refresh(
            recordRepository: repository,
            collectionRepository: collectionRepository
        )
        WidgetSyncService.sync(
            missionManager: missionManager,
            recordRepository: repository,
            streakManager: streakManager
        )
    }

    private func clearLocalUserDataIfNeeded(
        repository: RecordRepository,
        collectionRepository: CollectionRepository
    ) {
        repository.deleteAllRecords()
        collectionRepository.resetForSignedOutState()
        collectionStore.resetForSignedOutState()
        missionManager.resetForSignedOutState()
        WidgetDataStore.clearAll()
        streakManager.refresh(
            recordRepository: repository,
            collectionRepository: collectionRepository
        )
    }

    private func syncCustomCollectionsFromServer(
        collectionRepository: CollectionRepository
    ) async {
        guard let accessToken = authManager.accessToken else { return }
        await collectionRepository.syncCustomCollections(accessToken: accessToken)
    }

    private func syncRecordsFromServer(
        repository: RecordRepository,
        collectionRepository: CollectionRepository
    ) async {
        guard let accessToken = authManager.accessToken else { return }
        do {
            let records = try await RecordsAPIService.shared.fetchMyRecords(accessToken: accessToken)
            await repository.replaceAllRecordsFromServer(
                records,
                collectionRepository: collectionRepository
            )
            streakManager.refresh(
                recordRepository: repository,
                collectionRepository: collectionRepository
            )
            WidgetSyncService.sync(
                missionManager: missionManager,
                recordRepository: repository,
                streakManager: streakManager
            )
        } catch {
            debugPrint("syncRecordsFromServer failed:", error.localizedDescription)
        }
    }
}

// MARK: - Preview

#Preview {
    let (container, repository) = RecordPreviewData.makeRepository()
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()
    let streakManager = StreakManager()

    return MainTabView()
        .modelContainer(container)
        .environment(NotificationManager.mock)
        .environment(MissionManager.mock)
        .environment(AuthManager.mock)
        .environment(repository)
        .environment(collectionRepository)
        .environment(streakManager)
}
