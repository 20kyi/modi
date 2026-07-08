import SwiftUI

// MARK: - ConceptPickerView

/// 지난 발견 추가 시 Concept를 선택하는 화면.
struct ConceptPickerView: View {

    let concepts: [Concept]
    var onConceptSelected: (Concept) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                ForEach(CollectionCategory.allCases) { category in
                    let categoryConcepts = concepts.filter { $0.category == category }
                    if !categoryConcepts.isEmpty {
                        conceptSection(category: category, concepts: categoryConcepts)
                    }
                }
            }
            .appScreenPadding()
            .padding(.vertical, AppSpacing.md)
        }
        .appScreenBackground()
    }

    private func conceptSection(category: CollectionCategory, concepts: [Concept]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(category.displayName)
                .font(AppFont.headline)
                .foregroundStyle(AppColor.Text.primary)

            VStack(spacing: AppSpacing.sm) {
                ForEach(concepts) { concept in
                    Button {
                        onConceptSelected(concept)
                    } label: {
                        conceptRow(concept)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func conceptRow(_ concept: Concept) -> some View {
        HStack(spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(Color(hex: concept.themeColorHex))
                .frame(width: 48, height: 48)
                .overlay {
                    Text(concept.emoji)
                        .font(.system(size: 24))
                }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(concept.title)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.Text.primary)

                Text(concept.description)
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.Text.tertiary)
        }
        .appCardStyle()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConceptPickerView(concepts: Concept.systemConcepts) { _ in }
    }
}
