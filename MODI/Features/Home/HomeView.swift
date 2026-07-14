import SwiftData
import SwiftUI

struct HomeView: View {

    var missionManager: MissionManager
    var onCreateTapped: () -> Void = {}

    @Environment(RecordRepository.self) private var recordRepository
    @Environment(CollectionRepository.self) private var collectionRepository
    @Environment(StreakManager.self) private var streakManager
    @Environment(DeepLinkCoordinator.self) private var deepLinkCoordinator
    @Environment(AuthManager.self) private var authManager
    @Environment(PremiumManager.self) private var premiumManager
    @State private var viewModel = HomeViewModel()
    @State private var isShowingMissionChangeLimitSheet = false
    @State private var isShowingPremium = false

    private var isTodaysMissionCompleted: Bool {
        missionManager.isTodaysMissionCompleted(repository: recordRepository)
    }

    private var todaysMission: DailyMission {
        return missionManager.dailyMission(for: .now, isCompleted: isTodaysMissionCompleted)
            ?? .mock
    }

    private var canOfferMissionChange: Bool {
        missionManager.canOfferMissionChange(repository: recordRepository)
    }

    private var canPerformMissionChange: Bool {
        missionManager.canChangeMission(
            repository: recordRepository,
            hasPremium: premiumManager.hasPremium
        )
    }

    private var showsMissionChangeButton: Bool {
        if premiumManager.hasPremium {
            return canPerformMissionChange
        }
        return canOfferMissionChange
    }

    private var remainingMissionChanges: Int? {
        guard canOfferMissionChange else { return nil }
        return missionManager.remainingMissionChangeCount(hasPremium: premiumManager.hasPremium)
    }

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    homeContent
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xxxl)
                }
                .onChange(of: deepLinkCoordinator.pendingDestination) { _, destination in
                    guard destination == .todayMission else { return }
                    withAnimation(.easeInOut(duration: 0.45)) {
                        proxy.scrollTo(HomeScrollAnchor.todayMission, anchor: .center)
                    }
                    deepLinkCoordinator.consume(.todayMission)
                }
            }
            .appScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.Background.primary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
                if let record = recordRepository.records.first(where: { $0.id == navigationValue.id }),
                   let collection = record.collection ?? collectionRepository.collection(for: record.conceptId) {
                    RecordDetailView(record: record, collection: collection)
                }
            }
            .navigationDestination(for: CollectionNavigationValue.self) { navigationValue in
                if let collection = collectionRepository.collection(for: navigationValue.id) {
                    CollectionDetailView(collection: collection)
                }
            }
            .navigationDestination(isPresented: $isShowingPremium) {
                PremiumView()
            }
            .sheet(isPresented: $isShowingMissionChangeLimitSheet) {
                MissionChangeLimitSheet(
                    onShowPremium: {
                        isShowingMissionChangeLimitSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            isShowingPremium = true
                        }
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var homeContent: some View {
        if isPad {
            iPadHomeContent
        } else {
            iPhoneHomeContent
        }
    }

    private var iPhoneHomeContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
            headerSection

            todaysModiSection

            missionCard

            collectionPreviewSection

            recentDiscoverySection

            monthlyConceptSection
        }
        .appScreenPadding()
    }

    private var iPadHomeContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxl) {
            headerSection

            HStack(alignment: .top, spacing: AppSpacing.huge) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    todaysModiSection
                    missionCard
                    monthlyConceptSection
                }
                .frame(maxWidth: 430, alignment: .topLeading)

                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    collectionPreviewSection
                    recentDiscoverySection
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .padding(.horizontal, AppSpacing.huge)
        .frame(maxWidth: 1180, alignment: .leading)
    }

    private var missionCard: some View {
        DailyMissionCard(
            mission: todaysMission,
            onRecordTapped: isTodaysMissionCompleted ? nil : onCreateTapped,
            canOfferMissionChange: canOfferMissionChange,
            showsMissionChangeButton: showsMissionChangeButton,
            hasPremium: premiumManager.hasPremium,
            remainingMissionChanges: remainingMissionChanges,
            onChangeMissionTapped: rerollMission
        )
        .id(HomeScrollAnchor.todayMission)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(viewModel.greeting)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.Text.secondary)

            HStack(alignment: .center, spacing: AppSpacing.xs) {
                Text("\(authManager.session.displayName)님")
                    .font(AppFont.title1)
                    .foregroundStyle(AppColor.Text.primary)

                if premiumManager.hasPremium {
                    Text("✨ MODI+")
                        .font(AppFont.caption1.weight(.semibold))
                        .foregroundStyle(AppColor.Semantic.warning)
                        .accessibilityLabel("MODI+ 프리미엄")
                }
            }
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
                    onCreateTapped: isTodaysMissionCompleted ? nil : onCreateTapped,
                    presentation: isPad ? .grid : .carousel,
                    thumbnailSize: isPad ? 148 : 108
                )
            }
        }
    }

    // MARK: - Monthly Concept

    private var monthlyConceptSection: some View {
        MonthlyConceptPreviewView(concept: viewModel.monthlyConcept)
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
                        ? AppColor.Accent.highlight
                        : AppColor.Text.secondary
                )
        }
    }

    private func refreshData() {
        missionManager.syncCompletionStatus(repository: recordRepository)
        viewModel.refresh(
            missionManager: missionManager,
            recordRepository: recordRepository,
            collectionRepository: collectionRepository
        )
    }

    private func rerollMission() {
        if missionManager.canChangeMission(
            repository: recordRepository,
            hasPremium: premiumManager.hasPremium
        ) {
            guard missionManager.rerollMission(
                repository: recordRepository,
                hasPremium: premiumManager.hasPremium
            ) != nil else { return }
            refreshData()
            WidgetSyncService.sync(
                missionManager: missionManager,
                recordRepository: recordRepository,
                streakManager: streakManager
            )
        } else if !premiumManager.hasPremium {
            isShowingMissionChangeLimitSheet = true
        }
    }
}

private enum HomeScrollAnchor {
    static let todayMission = "todayMission"
}

#Preview("Light") {
    let (container, repository) = RecordPreviewData.makeRepository(withSampleData: true)
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()

    return HomeView(missionManager: .mock)
        .modelContainer(container)
        .environment(repository)
        .environment(collectionRepository)
        .environment(PremiumManager.shared)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    let (container, repository) = RecordPreviewData.makeRepository(withSampleData: true)
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()

    return HomeView(missionManager: .mock)
        .modelContainer(container)
        .environment(repository)
        .environment(collectionRepository)
        .environment(PremiumManager.shared)
        .preferredColorScheme(.dark)
}
