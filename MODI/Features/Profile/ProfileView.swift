import SwiftData
import SwiftUI

private struct SelectedCalendarDay: Identifiable {
    let id = UUID()
    let date: Date
}

struct ProfileView: View {

    @Environment(StreakManager.self) private var streakManager
    @Environment(RecordRepository.self) private var recordRepository
    @Environment(CollectionRepository.self) private var collectionRepository
    @Environment(MissionManager.self) private var missionManager
    @Environment(AuthManager.self) private var authManager
    @Environment(TitleCelebrationManager.self) private var titleCelebrationManager
    @Environment(EarnedTitleModalPresenter.self) private var earnedTitleModalPresenter
    @Environment(PremiumManager.self) private var premiumManager
    @State private var viewModel = ProfileViewModel()
    @State private var selectedCalendarDay: SelectedCalendarDay?
    @State private var pastDiscoveryPresentation: PastDiscoveryPresentation?
    @State private var isShowingLogin = false
    @State private var isShowingPremium = false
    @State private var uploadErrorMessage: String?

    private struct PastDiscoveryPresentation: Identifiable {
        let id = UUID()
        let date: Date
    }

    private var todaysMission: DailyMission {
        return missionManager.dailyMission(
            for: .now,
            isCompleted: missionManager.isTodaysMissionCompleted(repository: recordRepository)
        )
            ?? .mock
    }

    private var missionPlaceholder: ProfileTopCollection? {
        guard viewModel.stats.totalRecords == 0 else { return nil }

        return ProfileTopCollection(
            emoji: todaysMission.emoji,
            themeColorHex: todaysMission.themeColorHex
        )
    }

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    profileContent(availableWidth: proxy.size.width)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xxxl)
                }
            }
            .appScreenBackground()
            .navigationTitle("프로필")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.Background.primary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                refreshData()
            }
            .navigationDestination(isPresented: $isShowingPremium) {
                PremiumView()
            }
            .navigationDestination(for: CollectionNavigationValue.self) { navigationValue in
                if let collection = collectionRepository.collection(for: navigationValue.id) {
                    CollectionDetailView(collection: collection)
                }
            }
            .sheet(item: $selectedCalendarDay) { selection in
                DiscoveryDaySheet(
                    date: selection.date,
                    records: recordRepository.fetchRecords(on: selection.date),
                    onAddPastDiscovery: {
                        guard premiumManager.isPremium else { return }
                        let date = selection.date
                        selectedCalendarDay = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            pastDiscoveryPresentation = PastDiscoveryPresentation(date: date)
                        }
                    },
                    onShowPremium: {
                        selectedCalendarDay = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            isShowingPremium = true
                        }
                    }
                )
                .environment(collectionRepository)
            }
            .sheet(item: $pastDiscoveryPresentation) { presentation in
                PastDiscoveryFlowView(
                    selectedDate: presentation.date,
                    onCompleted: {
                        refreshData()
                        pastDiscoveryPresentation = nil
                    },
                    onUploadFailed: { error in
                        uploadErrorMessage = error.localizedDescription
                    }
                )
                .environment(authManager)
                .environment(missionManager)
                .environment(recordRepository)
                .environment(collectionRepository)
                .environment(streakManager)
                .environment(titleCelebrationManager)
            }
            .alert("서버에 기록을 저장하지 못했어요", isPresented: uploadErrorIsPresented) {
                Button("확인", role: .cancel) {
                    uploadErrorMessage = nil
                }
            } message: {
                Text(uploadErrorMessage ?? "기기에는 저장됐어요. 나중에 다시 시도해 주세요.")
            }
            .fullScreenCover(isPresented: $isShowingLogin) {
                LoginView {
                    isShowingLogin = false
                }
                .environment(authManager)
            }
        }
    }

    @ViewBuilder
    private func profileContent(availableWidth: CGFloat) -> some View {
        if isPad {
            iPadProfileContent(availableWidth: availableWidth)
        } else {
            iPhoneProfileContent
        }
    }

    private var iPhoneProfileContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
            profileHeaderSection
            guestSignInSection
            earnedBannersSection
            discoveryCalendarSection
            settingsSection
        }
        .appScreenPadding()
    }

    @ViewBuilder
    private func iPadProfileContent(availableWidth: CGFloat) -> some View {
        if availableWidth < 820 {
            iPadSingleColumnProfileContent
        } else {
            iPadTwoColumnProfileContent
        }
    }

    private var iPadSingleColumnProfileContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            profileHeaderSection
            guestSignInSection
            earnedBannersSection
            recentCollectionsSection
            discoveryCalendarSection
            settingsSection
        }
        .padding(.horizontal, AppSpacing.xxxl)
        .frame(maxWidth: 620, alignment: .leading)
    }

    private var iPadTwoColumnProfileContent: some View {
        HStack(alignment: .top, spacing: AppSpacing.huge) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                profileHeaderSection
                guestSignInSection
                earnedBannersSection
                settingsSection
            }
            .frame(width: 360, alignment: .topLeading)

            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                recentCollectionsSection
                discoveryCalendarSection
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, AppSpacing.huge)
        .frame(maxWidth: 1180, alignment: .leading)
    }

    private var profileHeaderSection: some View {
        ProfileHeaderCard(
            nickname: authManager.session.displayName,
            tagline: authManager.session.profileTagline,
            stats: viewModel.stats,
            nameSuffix: authManager.session.nameSuffix,
            isPremium: premiumManager.hasPremium,
            missionPlaceholder: missionPlaceholder
        )
    }

    @ViewBuilder
    private var guestSignInSection: some View {
        if authManager.session.isGuest {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Button("로그인하고 기록 보호하기") {
                    isShowingLogin = true
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("로그인은 기록 보호를 위한 선택이에요.")
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .appCardStyle()
        }
    }

    // MARK: - Discovery Calendar

    private var discoveryCalendarSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "발견 캘린더")

            DiscoveryCalendarView(
                recordedDayEmojis: viewModel.recordedDayEmojis,
                dayCellHeight: isPad ? 54 : 36,
                dayGridSpacing: isPad ? AppSpacing.md : AppSpacing.sm,
                onDaySelected: { date in
                    selectedCalendarDay = SelectedCalendarDay(date: date)
                }
            )
                .appCardStyle(padding: isPad ? AppSpacing.xl : AppSpacing.cardPadding)
        }
    }

    // MARK: - Earned Banners

    private let bannerGridColumns = Array(
        repeating: GridItem(.flexible(), spacing: AppSpacing.gridGutter),
        count: 4
    )

    private var earnedBannersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "획득한 배너")

            if viewModel.earnedBanners.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("아직 획득한 배너가 없어요")
                        .font(AppFont.subheadline)
                        .foregroundStyle(AppColor.Text.secondary)

                    Text("10개의 발견을 기록하면 첫 배너를 받을 수 있어요")
                        .font(AppFont.caption1)
                        .foregroundStyle(AppColor.Text.tertiary)
                }
                .appCardStyle()
            } else {
                LazyVGrid(columns: bannerGridColumns, spacing: AppSpacing.gridGutter) {
                    ForEach(viewModel.earnedBanners) { earnedBanner in
                        Button {
                            earnedTitleModalPresenter.present(earnedBanner)
                        } label: {
                            ProfileBannerCard(earnedBanner: earnedBanner)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - iPad Dashboard

    private var recentCollectionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "최근 컬렉션")

            if viewModel.collectionSummaries.isEmpty {
                EmptyStateView(
                    icon: "square.grid.2x2",
                    title: "아직 모인 컬렉션이 없어요",
                    message: "오늘의 미션으로 첫 컬렉션을 채워보세요"
                )
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 240), spacing: AppSpacing.md)],
                    spacing: AppSpacing.md
                ) {
                    ForEach(viewModel.collectionSummaries) { summary in
                        NavigationLink(value: CollectionNavigationValue(id: summary.id)) {
                            CollectionSummaryCard(summary: summary)
                        }
                        .buttonStyle(.plain)
                        .hoverEffect(.highlight)
                    }
                }
            }
        }
    }

    private var statsDashboardSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "통계")

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 160), spacing: AppSpacing.md)],
                spacing: AppSpacing.md
            ) {
                dashboardStatCard(value: "\(viewModel.stats.totalRecords)", label: "총 발견", icon: "sparkles")
                dashboardStatCard(value: "\(viewModel.stats.activeCollections)", label: "활성 컬렉션", icon: "square.grid.2x2.fill")
                dashboardStatCard(value: "\(viewModel.stats.monthlyRecords)", label: "이번 달 발견", icon: "calendar")
                dashboardStatCard(value: "\(viewModel.stats.streakDays)", label: "연속 발견", icon: "flame.fill")
            }
        }
    }

    private func dashboardStatCard(value: String, label: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColor.Accent.highlight)

            Text(value)
                .font(AppFont.title2)
                .foregroundStyle(AppColor.Text.primary)

            Text(label)
                .font(AppFont.footnote)
                .foregroundStyle(AppColor.Text.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle()
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "설정")

            VStack(spacing: 0) {
                NavigationLink {
                    PremiumView()
                } label: {
                    settingsRow(icon: "crown.fill", title: "MODI+", iconColor: AppColor.Semantic.warning)
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.leading, AppSpacing.lg + AppSpacing.xl + AppSpacing.md)

                NavigationLink {
                    SettingsView()
                } label: {
                    settingsRow(icon: "gearshape.fill", title: "설정", iconColor: AppColor.Accent.highlight)
                }
                .buttonStyle(.plain)
            }
            .appCardStyle(padding: 0)
        }
    }

    private func settingsRow(icon: String, title: String, iconColor: Color) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 28)

            Text(title)
                .font(AppFont.body)
                .foregroundStyle(AppColor.Text.primary)

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.Text.tertiary)
        }
        .settingsRowStyle()
    }

    // MARK: - Helpers

    private var uploadErrorIsPresented: Binding<Bool> {
        Binding(
            get: { uploadErrorMessage != nil },
            set: { if !$0 { uploadErrorMessage = nil } }
        )
    }

    private func refreshData() {
        streakManager.refresh(
            recordRepository: recordRepository,
            collectionRepository: collectionRepository
        )
        viewModel.refresh(
            streakManager: streakManager,
            recordRepository: recordRepository,
            collectionRepository: collectionRepository
        )
    }

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(AppFont.title3)
            .foregroundStyle(AppColor.Text.primary)
    }
}

// MARK: - Profile Banner Card

private struct ProfileBannerCard: View {

    private enum Layout {
        static let emojiHeight: CGFloat = 26
        static let bannerHeight: CGFloat = 26
        static let dateHeight: CGFloat = 24
    }

    let earnedBanner: ProfileHighestTitle

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(ProgressMilestone.hintEmoji(for: earnedBanner.title.milestone))
                .font(.system(size: 22))
                .frame(height: Layout.emojiHeight)

            Text(earnedBanner.title.name)
                .font(AppFont.caption2)
                .foregroundStyle(AppColor.Text.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: Layout.bannerHeight, maxHeight: Layout.bannerHeight, alignment: .center)

            Text(acquiredDateLabel)
                .font(.system(size: 10))
                .foregroundStyle(AppColor.Text.tertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: Layout.dateHeight, maxHeight: Layout.dateHeight, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .appCardStyle(padding: AppSpacing.sm)
    }

    private var acquiredDateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M.d"
        return "\(formatter.string(from: earnedBanner.acquiredDate))\n획득"
    }
}

#Preview("Light") {
    let (container, repository) = RecordPreviewData.makeRepository(withSampleData: true)
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()
    let streakManager = StreakManager()
    streakManager.refresh(recordRepository: repository, collectionRepository: collectionRepository)

    return ProfileView()
        .modelContainer(container)
        .environment(NotificationManager.mock)
        .environment(MissionManager.mock)
        .environment(AuthManager.mock)
        .environment(repository)
        .environment(collectionRepository)
        .environment(streakManager)
        .environment(EarnedTitleModalPresenter.mock)
        .environment(PremiumManager.shared)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    let (container, repository) = RecordPreviewData.makeRepository(withSampleData: true)
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()
    let streakManager = StreakManager()
    streakManager.refresh(recordRepository: repository, collectionRepository: collectionRepository)

    return ProfileView()
        .modelContainer(container)
        .environment(NotificationManager.mock)
        .environment(MissionManager.mock)
        .environment(AuthManager.mock)
        .environment(repository)
        .environment(collectionRepository)
        .environment(streakManager)
        .environment(EarnedTitleModalPresenter.mock)
        .environment(PremiumManager.shared)
    .preferredColorScheme(.dark)
}
