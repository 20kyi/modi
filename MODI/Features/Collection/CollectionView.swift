import SwiftData
import SwiftUI

struct CollectionView: View {

    @Environment(CollectionStore.self) private var store
    @Environment(RecordRepository.self) private var repository
    @Environment(CollectionRepository.self) private var collectionRepository
    @Environment(PremiumManager.self) private var premiumManager

    @State private var isShowingAddCollection = false
    @State private var isShowingCollectionLimitSheet = false
    @State private var isShowingPremium = false

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.gridGutter),
        GridItem(.flexible(), spacing: AppSpacing.gridGutter)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                    headerSection

                    ForEach(visibleCategories) { category in
                        categorySection(category)
                    }
                }
                .appScreenPadding()
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxxl)
            }
            .appScreenBackground()
            .navigationTitle("컬렉션")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.Background.primary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: attemptCreateCustomCollection) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .navigationDestination(isPresented: $isShowingAddCollection) {
                AddCollectionView()
            }
            .navigationDestination(isPresented: $isShowingPremium) {
                PremiumView()
            }
            .sheet(isPresented: $isShowingCollectionLimitSheet) {
                CustomCollectionLimitSheet(
                    onShowPremium: {
                        isShowingCollectionLimitSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            isShowingPremium = true
                        }
                    }
                )
            }
            .navigationDestination(for: PhotoCollection.self) { collection in
                CollectionDetailView(collection: collection)
            }
            .navigationDestination(for: RecordNavigationValue.self) { navigationValue in
                if let record = repository.records.first(where: { $0.id == navigationValue.id }) {
                    if let collection = record.collection ?? collectionRepository.collection(for: record.conceptId) {
                        RecordDetailView(record: record, collection: collection)
                    } else {
                        EmptyView()
                    }
                } else {
                    EmptyView()
                }
            }
        }
    }

    private var visibleCategories: [CollectionCategory] {
        [.color, .nature, .custom]
    }

    private var customCollectionCount: Int {
        collectionRepository.customCollections.count
    }

    private func attemptCreateCustomCollection() {
        if premiumManager.canCreateCustomCollection(currentCount: customCollectionCount) {
            isShowingAddCollection = true
        } else {
            isShowingCollectionLimitSheet = true
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("미션별로 사진이 모여요")
                .font(AppFont.title2)
                .foregroundStyle(AppColor.Text.primary)

            Text("매일 다른 미션을 수행하면 해당 컬렉션에 사진이 쌓입니다.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.Text.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func categorySection(_ category: CollectionCategory) -> some View {
        let collections = PhotoCollection.collections(in: category, custom: store.customCollections)

        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text(category.displayName)
                    .font(AppFont.title3)
                    .foregroundStyle(AppColor.Text.primary)

                if category == .custom {
                    Spacer()
                    Button(action: attemptCreateCustomCollection) {
                        Label("추가", systemImage: "plus.circle")
                            .font(AppFont.footnote)
                            .foregroundStyle(AppColor.Accent.highlight)
                    }
                }
            }

            if collections.isEmpty {
                Button(action: attemptCreateCustomCollection) {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppColor.Accent.highlight)

                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text("첫 커스텀 컬렉션 만들기")
                                .font(AppFont.subheadline)
                                .foregroundStyle(AppColor.Text.primary)

                            Text("나만의 미션을 추가해보세요")
                                .font(AppFont.caption1)
                                .foregroundStyle(AppColor.Text.secondary)
                        }

                        Spacer()
                    }
                    .appCardStyle()
                }
                .buttonStyle(.plain)
            } else {
                LazyVGrid(columns: columns, spacing: AppSpacing.gridGutter) {
                    ForEach(collections) { collection in
                        NavigationLink(value: collection) {
                            CollectionCard(
                                collection: collection,
                                photoCount: repository.photoCount(for: collection.id)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#Preview("Light") {
    let (container, repository) = RecordPreviewData.makeRepository(withSampleData: true, sampleDiscoveryCount: 12)
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()
    return CollectionView()
        .modelContainer(container)
        .environment(CollectionStore())
        .environment(repository)
        .environment(collectionRepository)
        .environment(TitleCelebrationManager())
        .environment(PremiumManager.shared)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    let (container, repository) = RecordPreviewData.makeRepository(withSampleData: true, sampleDiscoveryCount: 12)
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()
    return CollectionView()
        .modelContainer(container)
        .environment(CollectionStore())
        .environment(repository)
        .environment(collectionRepository)
        .environment(TitleCelebrationManager())
        .environment(PremiumManager.shared)
        .preferredColorScheme(.dark)
}
