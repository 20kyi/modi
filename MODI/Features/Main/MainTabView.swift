import SwiftData
import SwiftUI

// MARK: - Tab

enum MainTab: Hashable {
    case home
    case create
    case collection
    case profile
    case premium
    case settings
}

// MARK: - MainTabView

struct MainTabView: View {

    @Environment(AuthManager.self) private var authManager
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(MissionManager.self) private var missionManager
    @Environment(DeepLinkCoordinator.self) private var deepLinkCoordinator
    @Environment(PremiumManager.self) private var premiumManager
    @State private var collectionStore = CollectionStore()
    @State private var repository: RecordRepository?
    @State private var collectionRepository: CollectionRepository?
    @State private var streakManager = StreakManager()
    @State private var titleCelebrationManager = TitleCelebrationManager()
    @State private var earnedTitleModalPresenter = EarnedTitleModalPresenter()
    @State private var selectedTab: MainTab = .home
    @State private var isBootstrapping = true
    @AppStorage("modi.openCollectionAfterInitialLoad") private var openCollectionAfterInitialLoad = false

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

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

        return Group {
            if isPad {
                iPadSplitView
            } else {
                iPhoneTabView
            }
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
        .onChange(of: premiumManager.hasPremium) { _, hasPremium in
            missionManager.setPremiumAccess(hasPremium)
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

    private var iPhoneTabView: some View {
        TabView(selection: $selectedTab) {
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
    }

    private var iPadSplitView: some View {
        NavigationSplitView {
            MODISidebar(selection: $selectedTab)
                .navigationSplitViewColumnWidth(min: 260, ideal: 280, max: 300)
        } detail: {
            selectedSidebarDestination
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private var selectedSidebarDestination: some View {
        switch selectedTab {
        case .home:
            HomeView(
                missionManager: missionManager,
                onCreateTapped: { selectedTab = .create }
            )
        case .create:
            CreateView()
        case .collection:
            CollectionView()
        case .profile:
            ProfileView()
        case .premium:
            NavigationStack {
                ModiPlusView()
            }
        case .settings:
            NavigationStack {
                SettingsView()
            }
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
        missionManager.configure(
            collectionRepository: collectionRepo,
            hasPremiumAccess: premiumManager.hasPremium
        )
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
        missionManager.syncCompletionStatus(repository: repository)
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

// MARK: - iPad Sidebar

private struct MODISidebar: View {

    @Binding var selection: MainTab

    private let primaryItems: [MODISidebarItem] = [
        MODISidebarItem(tab: .home, title: "홈", systemImage: "house.fill", shortcut: "1"),
        MODISidebarItem(tab: .create, title: "만들기", systemImage: "plus.circle.fill", shortcut: "2"),
        MODISidebarItem(tab: .collection, title: "컬렉션", systemImage: "square.grid.2x2.fill", shortcut: "3"),
        MODISidebarItem(tab: .profile, title: "프로필", systemImage: "person.crop.circle.fill", shortcut: "4")
    ]

    private let utilityItems: [MODISidebarItem] = [
        MODISidebarItem(tab: .premium, title: "MODI+", systemImage: "crown.fill", shortcut: "5"),
        MODISidebarItem(tab: .settings, title: "설정", systemImage: "gearshape.fill", shortcut: ",")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxl) {
            sidebarHeader

            sidebarRows(primaryItems)

            Spacer(minLength: 0)

            VStack(spacing: AppSpacing.md) {
                Divider()
                    .background(AppColor.Border.subtle)
                    .padding(.horizontal, AppSpacing.sm)

                sidebarRows(utilityItems)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.xxl)
        .padding(.bottom, AppSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(sidebarGlassBackground)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(AppColor.Border.subtle.opacity(0.55))
                .frame(width: 0.5)
        }
    }

    private var sidebarGlassBackground: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            LinearGradient(
                colors: [
                    .white.opacity(0.72),
                    AppColor.Accent.soft.opacity(0.42),
                    AppColor.Surface.card.opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.screen)

            Circle()
                .fill(AppColor.Accent.highlight.opacity(0.12))
                .frame(width: 180, height: 180)
                .blur(radius: 42)
                .offset(x: -72, y: -110)

            Circle()
                .fill(AppColor.Accent.soft.opacity(0.24))
                .frame(width: 220, height: 220)
                .blur(radius: 56)
                .offset(x: 96, y: 240)

            Rectangle()
                .fill(AppColor.Background.primary.opacity(0.10))
        }
        .ignoresSafeArea()
    }

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("MODI")
                .font(AppFont.Rounded.title)
                .foregroundStyle(AppColor.Text.primary)

            Text("오늘의 순간을 발견하세요")
                .font(AppFont.caption1)
                .foregroundStyle(AppColor.Text.secondary)
        }
        .padding(.horizontal, AppSpacing.sm)
    }

    private func sidebarRows(_ items: [MODISidebarItem]) -> some View {
        VStack(spacing: AppSpacing.xs) {
            ForEach(items) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selection = item.tab
                    }
                } label: {
                    sidebarRow(item)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(KeyEquivalent(Character(item.shortcut)), modifiers: .command)
                .hoverEffect(.highlight)
            }
        }
    }

    private func sidebarRow(_ item: MODISidebarItem) -> some View {
        let isSelected = selection == item.tab

        return HStack(spacing: AppSpacing.md) {
            Image(systemName: item.systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isSelected ? AppColor.Accent.highlight : AppColor.Text.secondary)
                .frame(width: 24)

            Text(item.title)
                .font(AppFont.headline)
                .foregroundStyle(AppColor.Text.primary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .fill(AppColor.Accent.highlight.opacity(0.18))
                    }
            }
        }
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.82),
                                AppColor.Accent.highlight.opacity(0.42),
                                AppColor.Border.subtle.opacity(0.28)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .shadow(color: AppColor.Accent.highlight.opacity(0.12), radius: 10, x: 0, y: 4)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct MODISidebarItem: Identifiable {
    let tab: MainTab
    let title: String
    let systemImage: String
    let shortcut: String

    var id: MainTab { tab }
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
        .environment(PremiumManager.shared)
        .environment(repository)
        .environment(collectionRepository)
        .environment(streakManager)
}
