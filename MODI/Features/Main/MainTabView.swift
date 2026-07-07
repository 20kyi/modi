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
    @State private var collectionStore = CollectionStore()
    @State private var missionManager = MissionManager()
    @State private var repository: MODIRepository?
    @State private var selectedTab: MainTab = .home

    var body: some View {
        Group {
            if let repository {
                tabView(repository: repository)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if repository == nil {
                repository = MODIRepository(modelContext: modelContext)
            }
        }
    }

    private func tabView(repository: MODIRepository) -> some View {
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
    }
}

// MARK: - Preview

#Preview {
    let (container, repository) = MODIPreviewData.makeRepository()
    return MainTabView()
        .modelContainer(container)
        .environment(repository)
}
