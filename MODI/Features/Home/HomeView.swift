import SwiftData
import SwiftUI

struct HomeView: View {

    var missionManager: MissionManager
    var onCreateTapped: () -> Void = {}

    @Environment(RecordRepository.self) private var recordRepository
    @Environment(CollectionRepository.self) private var collectionRepository
    @State private var viewModel = HomeViewModel()

    private var isTodaysMissionCompleted: Bool {
        missionManager.isTodaysMissionCompleted(repository: recordRepository)
    }

    private var todaysMission: DailyMission {
        missionManager.dailyMission(for: .now, isCompleted: isTodaysMissionCompleted)
            ?? .mock
    }

    private var canChangeMission: Bool {
        missionManager.canChangeMission(repository: recordRepository)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                    headerSection

                    todaysModiSection

                    DailyMissionCard(
                        mission: todaysMission,
                        onRecordTapped: isTodaysMissionCompleted ? nil : onCreateTapped,
                        canChangeMission: canChangeMission,
                        onChangeMissionTapped: rerollMission
                    )

                    recentDiscoverySection

                    collectionPreviewSection
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
            .onAppear {
                refreshData()
            }
            .onChange(of: recordRepository.records.count) {
                refreshData()
            }
            .navigationDestination(for: RecordNavigationValue.self) { navigationValue in
                if let gallery = viewModel.todaysMissionGallery,
                   let record = gallery.records.first(where: { $0.id == navigationValue.id }),
                   let collection = collectionRepository.collection(for: gallery.collectionID) {
                    RecordDetailView(record: record, collection: collection)
                }
            }
            .navigationDestination(for: CollectionNavigationValue.self) { navigationValue in
                if let collection = collectionRepository.collection(for: navigationValue.id) {
                    CollectionDetailView(collection: collection)
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

    // MARK: - Recent Discovery

    private var recentDiscoverySection: some View {
        Group {
            if viewModel.recentDiscoveries.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("최근 발견")
                        .font(AppFont.title3)
                        .foregroundStyle(AppColor.Text.primary)

                    EmptyStateView(
                        icon: "sparkles",
                        title: "아직 발견이 없어요",
                        message: "오늘의 미션으로 첫 기록을 남겨보세요",
                        actionTitle: "기록하기",
                        action: onCreateTapped
                    )
                }
            } else {
                RecentDiscoveryView(discoveries: viewModel.recentDiscoveries)
            }
        }
    }

    // MARK: - Collection Preview

    private var collectionPreviewSection: some View {
        Group {
            if let gallery = viewModel.todaysMissionGallery {
                CollectionPreviewView(
                    gallery: gallery,
                    onCreateTapped: isTodaysMissionCompleted ? nil : onCreateTapped
                )
            }
        }
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

    private func refreshData() {
        viewModel.refresh(
            missionManager: missionManager,
            recordRepository: recordRepository,
            collectionRepository: collectionRepository
        )
    }

    private func rerollMission() {
        guard missionManager.rerollMission(repository: recordRepository) != nil else { return }
        refreshData()
    }
}

#Preview {
    let (container, repository) = RecordPreviewData.makeRepository(withSampleData: true)
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()

    return HomeView(missionManager: .mock)
        .modelContainer(container)
        .environment(repository)
        .environment(collectionRepository)
}
