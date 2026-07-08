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

    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(MissionManager.self) private var missionManager
    @State private var collectionStore = CollectionStore()
    @State private var repository: RecordRepository?
    @State private var collectionRepository: CollectionRepository?
    @State private var selectedTab: MainTab = .home

    var body: some View {
        Group {
            if let repository, let collectionRepository {
                tabView(repository: repository, collectionRepository: collectionRepository)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if repository == nil {
                let recordRepository = RecordRepository(modelContext: modelContext)
                let collectionRepo = CollectionRepository(modelContext: modelContext)
                collectionRepo.bootstrap()
                collectionStore.configure(collectionRepository: collectionRepo)
                repository = recordRepository
                collectionRepository = collectionRepo
            }
        }
    }

    private func tabView(
        repository: RecordRepository,
        collectionRepository: CollectionRepository
    ) -> some View {
        TabView(selection: $selectedTab) {
            HomeView(
                missionManager: missionManager,
                repository: repository,
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
        .tint(AppColor.Accent.primary)
        .environment(collectionStore)
        .environment(missionManager)
        .environment(repository)
        .environment(collectionRepository)
        .task {
            if notificationManager.isEnabled {
                await notificationManager.scheduleDailyNotifications(missionManager: missionManager)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let (container, repository) = RecordPreviewData.makeRepository()
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()

    return MainTabView()
        .modelContainer(container)
        .environment(NotificationManager.mock)
        .environment(MissionManager.mock)
        .environment(repository)
        .environment(collectionRepository)
}
