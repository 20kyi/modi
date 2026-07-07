import SwiftUI

struct ConceptSelectView: View {

    private let concepts = Concept.mockConcepts

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.gridGutter),
        GridItem(.flexible(), spacing: AppSpacing.gridGutter)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                headerSection

                ForEach(ConceptCategory.allCases) { category in
                    categorySection(category)
                }
            }
            .appScreenPadding()
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .appScreenBackground()
        .navigationTitle("컨셉 선택")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Concept.self) { concept in
            ConceptNextStepView(concept: concept)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("어떤 순간을 모을까요?")
                .font(AppFont.title2)
                .foregroundStyle(AppColor.Text.primary)

            Text("마음에 드는 컨셉을 골라 일상의 발견을 기록해보세요.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.Text.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Category Section

    private func categorySection(_ category: ConceptCategory) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(category.displayName)
                .font(AppFont.title3)
                .foregroundStyle(AppColor.Text.primary)

            LazyVGrid(columns: columns, spacing: AppSpacing.gridGutter) {
                ForEach(concepts.filter { $0.category == category }) { concept in
                    NavigationLink(value: concept) {
                        ConceptCard(concept: concept)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Next Step Placeholder

/// 선택한 컨셉으로 이어질 다음 화면의 임시 플레이스홀더.
struct ConceptNextStepView: View {

    let concept: Concept

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Text(concept.emoji)
                .font(.system(size: 64))

            VStack(spacing: AppSpacing.sm) {
                Text(concept.title)
                    .font(AppFont.title2)
                    .foregroundStyle(AppColor.Text.primary)

                Text(concept.description)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.Text.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("다음 단계에서 사진을 추가할 수 있어요.")
                .font(AppFont.footnote)
                .foregroundStyle(AppColor.Text.tertiary)
                .padding(.top, AppSpacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appScreenBackground()
        .navigationTitle("컨셉 확인")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview("Concept Select") {
    NavigationStack {
        ConceptSelectView()
    }
}

#Preview("Next Step") {
    NavigationStack {
        ConceptNextStepView(concept: Concept.mockConcepts[0])
    }
}
