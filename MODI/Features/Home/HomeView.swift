import SwiftUI

struct HomeView: View {

    @State private var viewModel = HomeViewModel()
    var onCreateTapped: () -> Void = {}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                    headerSection
                    createCTASection
                    recentItemsSection
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

    private var createCTASection: some View {
        Button(action: onCreateTapped) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(AppColor.Text.onAccent)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("나만의 아이템 만들기")
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.Text.onAccent)

                    Text("오늘의 한 장으로 시작해요")
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.onAccent.opacity(0.8))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.Text.onAccent.opacity(0.8))
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
    }

    // MARK: - Recent Items

    private var recentItemsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "최근 제작한 아이템")

            if viewModel.recentItems.isEmpty {
                EmptyStateView(
                    icon: "photo.on.rectangle.angled",
                    title: "아직 제작한 아이템이 없어요",
                    message: "첫 번째 아이템을 만들어보세요.",
                    actionTitle: "만들기",
                    action: onCreateTapped
                )
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: AppSpacing.gridGutter),
                        GridItem(.flexible(), spacing: AppSpacing.gridGutter)
                    ],
                    spacing: AppSpacing.gridGutter
                ) {
                    ForEach(viewModel.recentItems) { item in
                        HomeItemCard(item: item, style: .compact)
                    }
                }
            }
        }
    }

    // MARK: - Recommended

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "추천 아이템")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.itemGap) {
                    ForEach(viewModel.recommendedItems) { item in
                        HomeItemCard(item: item, style: .featured)
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
}

// MARK: - Home Item Card

private enum HomeItemCardStyle {
    case compact
    case featured
}

private struct HomeItemCard: View {

    let item: HomeItem
    let style: HomeItemCardStyle

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                .fill(item.themeColor)
                .aspectRatio(style == .featured ? 0.75 : 1.0, contentMode: .fit)
                .overlay {
                    Image(systemName: item.icon)
                        .font(.system(size: style == .featured ? 32 : 24, weight: .light))
                        .foregroundStyle(AppColor.Accent.primary.opacity(0.5))
                }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(item.title)
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(AppFont.caption1)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(2)
            }
        }
        .frame(width: style == .featured ? 160 : nil)
        .appCardStyle(padding: AppSpacing.md)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
