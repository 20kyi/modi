import SwiftData
import SwiftUI

struct RecommendedCollectionAddSheet: View {

    @Environment(CollectionRepository.self) private var collectionRepository
    @Environment(AuthManager.self) private var authManager
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(\.dismiss) private var dismiss

    let template: RecommendedCollectionTemplate

    @State private var isShowingCollectionLimitSheet = false
    @State private var isShowingPremium = false

    private var isAlreadyAdded: Bool {
        collectionRepository.hasAddedTemplate(template.id)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                VStack(spacing: AppSpacing.md) {
                    RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                        .fill(template.themeColor)
                        .frame(width: 100, height: 100)
                        .overlay {
                            Image(systemName: template.icon)
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(AppColor.Accent.highlight.opacity(0.5))
                        }
                        .appShadow(.medium)

                    VStack(spacing: AppSpacing.xs) {
                        Text(template.title)
                            .font(AppFont.title2)
                            .foregroundStyle(AppColor.Text.primary)

                        Text(template.subtitle)
                            .font(AppFont.callout)
                            .foregroundStyle(AppColor.Text.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, AppSpacing.lg)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("미션 문구")
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.Text.primary)

                    Text(template.missionPrompt)
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.Text.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCardStyle()

                Spacer()

                if isAlreadyAdded {
                    Label("이미 추가된 컬렉션이에요", systemImage: "checkmark.circle.fill")
                        .font(AppFont.subheadline)
                        .foregroundStyle(AppColor.Semantic.success)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            AppColor.Semantic.success.opacity(0.1),
                            in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        )
                } else {
                    Button("컬렉션에 추가하기") {
                        attemptAddCustomCollection()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .appScreenPadding()
            .padding(.bottom, AppSpacing.xl)
            .appScreenBackground()
            .navigationTitle("추천 컨셉")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(AppColor.Accent.highlight)
                }
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
        }
        .presentationDetents([.medium])
    }

    private func attemptAddCustomCollection() {
        if premiumManager.canCreateCustomCollection(in: collectionRepository.collections) {
            collectionRepository.addCustomCollection(
                from: template,
                accessToken: authManager.accessToken
            )
            dismiss()
        } else {
            isShowingCollectionLimitSheet = true
        }
    }
}

#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let schema = Schema([MODIRecord.self, MODICollection.self])
    let container = try! ModelContainer(for: schema, configurations: configuration)
    let collectionRepository = CollectionPreviewData.makeRepository(modelContext: container.mainContext)

    return RecommendedCollectionAddSheet(template: RecommendedCollectionTemplate.all[0])
        .modelContainer(container)
        .environment(collectionRepository)
}
