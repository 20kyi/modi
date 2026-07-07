import SwiftUI

struct HomeView: View {

    var collectionStore: CollectionStore
    var onCreateTapped: () -> Void = {}

    @State private var viewModel = HomeViewModel()

    private var todaysMission: DailyMission {
        let mission = collectionStore.todaysMission
        return mission.with(isCompleted: collectionStore.isTodaysMissionCompleted)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                    headerSection

                    todaysModiSection

                    DailyMissionCard(
                        mission: todaysMission,
                        onRecordTapped: collectionStore.isTodaysMissionCompleted ? nil : onCreateTapped
                    )

                    RecentDiscoveryView(discoveries: viewModel.recentDiscoveries)

                    CollectionPreviewView(collections: viewModel.collectionPreviews)
                }
                .appScreenPadding()
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxxl)
            }
            .appScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("MODI")
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.Text.primary)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(viewModel.greeting)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.Text.secondary)

            Text("\(viewModel.userName)님")
                .font(AppFont.title1)
                .foregroundStyle(AppColor.Text.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Today's MODI

    private var todaysModiSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("오늘의 MODI")
                .font(AppFont.title3)
                .foregroundStyle(AppColor.Text.primary)

            Text(viewModel.missionStatusMessage(isCompleted: collectionStore.isTodaysMissionCompleted))
                .font(AppFont.subheadline)
                .foregroundStyle(
                    collectionStore.isTodaysMissionCompleted
                        ? AppColor.Accent.primary
                        : AppColor.Text.secondary
                )
        }
    }
}

#Preview {
    HomeView(collectionStore: CollectionStore())
}
