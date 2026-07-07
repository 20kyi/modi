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

    @State private var selectedTab: MainTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(onCreateTapped: { selectedTab = .create })
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
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}
