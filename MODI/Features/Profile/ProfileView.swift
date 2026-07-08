import SwiftData
import SwiftUI

struct ProfileView: View {

    @Environment(NotificationManager.self) private var notificationManager
    @Environment(StreakManager.self) private var streakManager
    @Environment(RecordRepository.self) private var recordRepository
    @Environment(CollectionRepository.self) private var collectionRepository
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                    ProfileHeaderCard(
                        nickname: viewModel.nickname,
                        tagline: viewModel.tagline,
                        stats: viewModel.stats
                    )

                    discoveryCalendarSection
                    monthlyConceptSection
                    collectionSummarySection
                    settingsSection
                }
                .appScreenPadding()
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxxl)
            }
            .appScreenBackground()
            .navigationTitle("프로필")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                refreshData()
            }
        }
    }

    // MARK: - Discovery Calendar

    private var discoveryCalendarSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "발견 캘린더")

            DiscoveryCalendarView(recordedDayEmojis: viewModel.recordedDayEmojis)
                .appCardStyle()
        }
    }

    // MARK: - Monthly Concept

    private var monthlyConceptSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: viewModel.monthlyConcept.monthLabel)

            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                HStack(spacing: AppSpacing.md) {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(Color(hex: viewModel.monthlyConcept.themeColorHex))
                        .frame(width: 56, height: 56)
                        .overlay {
                            Text(viewModel.monthlyConcept.emoji)
                                .font(.system(size: 28))
                        }

                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(viewModel.monthlyConcept.title)
                            .font(AppFont.title3)
                            .foregroundStyle(AppColor.Text.primary)

                        Text("이번 달 기록: \(viewModel.monthlyConcept.currentRecordCount)개")
                            .font(AppFont.footnote)
                            .foregroundStyle(AppColor.Text.secondary)
                    }
                }

                Button("기록 보기") {
                    // TODO: 월간 컨셉 기록 화면으로 이동
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .appCardStyle()
        }
    }

    // MARK: - Collection Summary

    private var collectionSummarySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "나의 발견")

            if viewModel.collectionSummaries.isEmpty {
                EmptyStateView(
                    icon: "camera.fill",
                    title: "아직 발견이 없어요",
                    message: "오늘의 컨셉으로 첫 기록을 남겨보세요"
                )
                .appCardStyle()
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.collectionSummaries) { summary in
                        Button {
                            // TODO: 컬렉션 상세로 이동
                        } label: {
                            CollectionSummaryCard(summary: summary)
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
                ForEach(Array(viewModel.settingsItems.enumerated()), id: \.element.id) { index, item in
                    settingsRowLink(for: item)

                    if index < viewModel.settingsItems.count - 1 {
                        Divider()
                            .padding(.leading, AppSpacing.lg + AppSpacing.xl + AppSpacing.md)
                    }
                }
            }
            .appCardStyle(padding: 0)
        }
    }

    @ViewBuilder
    private func settingsRowLink(for item: ProfileSettingsItem) -> some View {
        switch item.destination {
        case .notifications:
            NavigationLink {
                NotificationSettingsView()
            } label: {
                settingsRow(item: item, subtitle: notificationSubtitle)
            }
            .buttonStyle(.plain)

        case .premium, .appSettings:
            Button {
                // TODO: 설정 항목 액션
            } label: {
                settingsRow(item: item, subtitle: nil)
            }
            .buttonStyle(.plain)
        }
    }

    private var notificationSubtitle: String? {
        guard notificationManager.isEnabled else { return "꺼짐" }
        return notificationManager.formattedNotificationTime
    }

    private func settingsRow(item: ProfileSettingsItem, subtitle: String?) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: item.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(item.isPremium ? AppColor.Semantic.warning : AppColor.Accent.primary)
                .frame(width: 28)

            Text(item.title)
                .font(AppFont.body)
                .foregroundStyle(AppColor.Text.primary)

            Spacer()

            if let subtitle {
                Text(subtitle)
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.tertiary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.Text.tertiary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .frame(minHeight: AppSpacing.minTouchTarget)
    }

    // MARK: - Helpers

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

#Preview {
    let (container, repository) = RecordPreviewData.makeRepository(withSampleData: true)
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()
    let streakManager = StreakManager()
    streakManager.refresh(recordRepository: repository, collectionRepository: collectionRepository)

    return ProfileView()
        .modelContainer(container)
        .environment(NotificationManager.mock)
        .environment(MissionManager.mock)
        .environment(repository)
        .environment(collectionRepository)
        .environment(streakManager)
}
