import SwiftUI

struct HomeView: View {

    var missionManager: MissionManager
    var repository: MODIRepository
    var onCreateTapped: () -> Void = {}

    @State private var viewModel = HomeViewModel()

    private var isTodaysMissionCompleted: Bool {
        missionManager.isTodaysMissionCompleted(repository: repository)
    }

    private var todaysMission: DailyMission {
        missionManager.dailyMission(for: .now, isCompleted: isTodaysMissionCompleted)
            ?? .mock
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                    headerSection

                    todaysModiSection

                    DailyMissionCard(
                        mission: todaysMission,
                        onRecordTapped: isTodaysMissionCompleted ? nil : onCreateTapped
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

            Text(viewModel.missionStatusMessage(isCompleted: isTodaysMissionCompleted))
                .font(AppFont.subheadline)
                .foregroundStyle(
                    isTodaysMissionCompleted
                        ? AppColor.Accent.primary
                        : AppColor.Text.secondary
                )
        }
    }
}

#Preview {
    let (_, repository) = MODIPreviewData.makeRepository()
    return HomeView(missionManager: .mock, repository: repository)
}
