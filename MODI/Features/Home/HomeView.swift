import SwiftUI

struct HomeView: View {

    var collectionStore: CollectionStore
    var onCreateTapped: () -> Void = {}

    @State private var viewModel = HomeViewModel()
    @State private var selectedTemplate: RecommendedCollectionTemplate?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                    headerSection

                    if let collection = collectionStore.todaysCollection {
                        DailyMissionCard(
                            mission: collectionStore.todaysMission,
                            collection: collection,
                            isCompleted: collectionStore.isTodaysMissionCompleted
                        )
                    }

                    primaryCTASection
                    myCollectionsSection
                    recommendedSection
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
            .sheet(item: $selectedTemplate) { template in
                RecommendedCollectionAddSheet(template: template)
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

    // MARK: - CTA

    private var primaryCTASection: some View {
        Button(action: onCreateTapped) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: collectionStore.isTodaysMissionCompleted ? "checkmark.circle.fill" : "camera.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(AppColor.Text.onAccent)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(collectionStore.isTodaysMissionCompleted ? "오늘 미션 완료!" : "오늘의 미션 수행하기")
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.Text.onAccent)

                    Text(collectionStore.isTodaysMissionCompleted
                         ? "내일 새로운 미션이 도착해요"
                         : collectionStore.todaysMission.prompt)
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.onAccent.opacity(0.8))
                        .lineLimit(1)
                }

                Spacer()

                if !collectionStore.isTodaysMissionCompleted {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColor.Text.onAccent.opacity(0.8))
                }
            }
            .padding(AppSpacing.lg)
            .background(
                LinearGradient(
                    colors: [AppColor.Accent.primary, AppColor.Accent.pressed],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
            )
            .appShadow(.medium)
        }
        .buttonStyle(.plain)
        .disabled(collectionStore.isTodaysMissionCompleted)
        .opacity(collectionStore.isTodaysMissionCompleted ? 0.85 : 1)
    }

    // MARK: - My Collections

    private var myCollectionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "내 컬렉션")

            let activeCollections = collectionStore.allCollections
                .filter { collectionStore.photoCount(for: $0.id) > 0 }
                .sorted { collectionStore.photoCount(for: $0.id) > collectionStore.photoCount(for: $1.id) }

            if activeCollections.isEmpty {
                EmptyStateView(
                    icon: "square.grid.2x2",
                    title: "아직 모은 사진이 없어요",
                    message: "오늘의 미션을 수행하면 컬렉션이 채워져요.",
                    actionTitle: "미션 하러 가기",
                    action: onCreateTapped
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.itemGap) {
                        ForEach(activeCollections.prefix(6)) { collection in
                            ActiveCollectionCard(
                                collection: collection,
                                photoCount: collectionStore.photoCount(for: collection.id)
                            )
                        }
                    }
                }
            }
        }
    }

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(AppFont.title3)
            .foregroundStyle(AppColor.Text.primary)
    }

    // MARK: - Recommended

    /// 화면에 카드 2개가 온전히 보이도록 외곽 너비 계산.
    private var recommendedCardWidth: CGFloat {
        let contentWidth = UIScreen.main.bounds.width - AppSpacing.screenHorizontal * 2
        return (contentWidth - AppSpacing.itemGap) / 2
    }

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "추천 컨셉")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.itemGap) {
                    ForEach(viewModel.recommendedTemplates) { template in
                        RecommendedConceptCard(
                            template: template,
                            cardWidth: recommendedCardWidth,
                            isAdded: collectionStore.hasAddedTemplate(template.id)
                        ) {
                            selectedTemplate = template
                        }
                    }
                }
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

// MARK: - Recommended Concept Card

private struct RecommendedConceptCard: View {

    let template: RecommendedCollectionTemplate
    let cardWidth: CGFloat
    let isAdded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                    .fill(template.themeColor)
                    .aspectRatio(0.77, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        Image(systemName: template.icon)
                            .font(.system(size: 32, weight: .light))
                            .foregroundStyle(AppColor.Accent.primary.opacity(0.5))
                    }
                    .overlay(alignment: .topTrailing) {
                        if isAdded {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(AppColor.Semantic.success)
                                .padding(AppSpacing.sm)
                        }
                    }

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(template.title)
                        .font(AppFont.subheadline)
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(1)

                    Text(template.subtitle)
                        .font(AppFont.caption1)
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .appCardStyle(padding: AppSpacing.md)
            .frame(width: cardWidth)
        }
        .buttonStyle(.plain)
        .scrollTargetLayout()
    }
}

// MARK: - Active Collection Card

private struct ActiveCollectionCard: View {

    let collection: PhotoCollection
    let photoCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                .fill(collection.themeColor)
                .frame(width: 140, height: 100)
                .overlay {
                    Text(collection.emoji)
                        .font(.system(size: 32))
                }
                .overlay(alignment: .bottomTrailing) {
                    Text("\(photoCount)장")
                        .font(AppFont.caption2)
                        .foregroundStyle(AppColor.Text.onAccent)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(AppColor.Accent.primary.opacity(0.85), in: Capsule())
                        .padding(AppSpacing.sm)
                }

            Text(collection.title)
                .font(AppFont.subheadline)
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(1)
        }
        .frame(width: 140)
    }
}

#Preview {
    HomeView(collectionStore: CollectionStore())
}
