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
    @State private var viewModel = ProfileViewModel()
    @State private var selectedCalendarDay: SelectedCalendarDay?
    @State private var pastDiscoveryPresentation: PastDiscoveryPresentation?
    @State private var isShowingLogin = false
    @State private var uploadErrorMessage: String?

    private struct PastDiscoveryPresentation: Identifiable {
        let id = UUID()
        let date: Date
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                    ProfileHeaderCard(
                        nickname: authManager.session.displayName,
                        tagline: authManager.session.profileTagline,
                        stats: viewModel.stats,
                        nameSuffix: authManager.session.nameSuffix
                    )

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

                    discoveryCalendarSection
                    earnedTitlesSection
                    settingsSection
                }
                .appScreenPadding()
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxxl)
            }
            .appScreenBackground()
            .navigationTitle("프로필")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.Background.primary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                refreshData()
            }
            .sheet(item: $selectedCalendarDay) { selection in
                DiscoveryDaySheet(
                    date: selection.date,
                    records: recordRepository.fetchRecords(on: selection.date),
                    onAddPastDiscovery: {
                        let date = selection.date
                        selectedCalendarDay = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            pastDiscoveryPresentation = PastDiscoveryPresentation(date: date)
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

    // MARK: - Discovery Calendar

    private var discoveryCalendarSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "발견 캘린더")

            DiscoveryCalendarView(
                recordedDayEmojis: viewModel.recordedDayEmojis,
                onDaySelected: { date in
                    selectedCalendarDay = SelectedCalendarDay(date: date)
                }
            )
                .appCardStyle()
        }
    }

    // MARK: - Earned Titles

    private let titleGridColumns = Array(
        repeating: GridItem(.flexible(), spacing: AppSpacing.gridGutter),
        count: 4
    )

    private var earnedTitlesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "획득한 Title")

            if viewModel.earnedTitles.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("아직 획득한 Title이 없어요")
                        .font(AppFont.subheadline)
                        .foregroundStyle(AppColor.Text.secondary)

                    Text("10개의 발견을 기록하면 첫 Title을 받을 수 있어요")
                        .font(AppFont.caption1)
                        .foregroundStyle(AppColor.Text.tertiary)
                }
                .appCardStyle()
            } else {
                LazyVGrid(columns: titleGridColumns, spacing: AppSpacing.gridGutter) {
                    ForEach(viewModel.earnedTitles) { earnedTitle in
                        Button {
                            earnedTitleModalPresenter.present(earnedTitle)
                        } label: {
                            ProfileTitleCard(earnedTitle: earnedTitle)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "설정")

            VStack(spacing: 0) {
                Button {
                    // TODO: Premium 화면 연결
                } label: {
                    settingsRow(icon: "crown.fill", title: "Premium", iconColor: AppColor.Semantic.warning)
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.leading, AppSpacing.lg + AppSpacing.xl + AppSpacing.md)

                NavigationLink {
                    SettingsView()
                } label: {
                    settingsRow(icon: "gearshape.fill", title: "설정 열기", iconColor: AppColor.Accent.primary)
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

// MARK: - Profile Title Card

private struct ProfileTitleCard: View {

    private enum Layout {
        static let emojiHeight: CGFloat = 26
        static let titleHeight: CGFloat = 26
        static let dateHeight: CGFloat = 24
    }

    let earnedTitle: ProfileHighestTitle

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(ProgressMilestone.hintEmoji(for: earnedTitle.title.milestone))
                .font(.system(size: 22))
                .frame(height: Layout.emojiHeight)

            Text(earnedTitle.title.name)
                .font(AppFont.caption2)
                .foregroundStyle(AppColor.Text.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: Layout.titleHeight, maxHeight: Layout.titleHeight, alignment: .center)

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
        return "\(formatter.string(from: earnedTitle.acquiredDate))\n획득"
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
        .preferredColorScheme(.dark)
}
