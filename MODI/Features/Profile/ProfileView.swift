import SwiftUI

struct ProfileView: View {

    @State private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                    ProfileHeaderCard(
                        profile: viewModel.profile,
                        tagline: viewModel.tagline
                    )

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

                        Text("현재 기록 개수: \(viewModel.monthlyConcept.currentRecordCount)개")
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

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "설정")

            VStack(spacing: 0) {
                ForEach(Array(viewModel.settingsItems.enumerated()), id: \.element.id) { index, item in
                    Button {
                        // TODO: 설정 항목 액션
                    } label: {
                        settingsRow(item: item)
                    }
                    .buttonStyle(.plain)

                    if index < viewModel.settingsItems.count - 1 {
                        Divider()
                            .padding(.leading, AppSpacing.lg + AppSpacing.xl + AppSpacing.md)
                    }
                }
            }
            .appCardStyle(padding: 0)
        }
    }

    private func settingsRow(item: ProfileSettingsItem) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: item.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(item.isPremium ? AppColor.Semantic.warning : AppColor.Accent.primary)
                .frame(width: 28)

            Text(item.title)
                .font(AppFont.body)
                .foregroundStyle(AppColor.Text.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.Text.tertiary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .frame(minHeight: AppSpacing.minTouchTarget)
    }

    // MARK: - Helpers

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(AppFont.title3)
            .foregroundStyle(AppColor.Text.primary)
    }
}

#Preview {
    ProfileView()
}
