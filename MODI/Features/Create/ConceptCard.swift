import SwiftUI

struct ConceptCard: View {

    let concept: Concept

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                .fill(concept.themeColor)
                .aspectRatio(1.0, contentMode: .fit)
                .overlay {
                    Text(concept.emoji)
                        .font(.system(size: 36))
                }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(concept.title)
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1)

                Text(concept.description)
                    .font(AppFont.caption1)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .appCardStyle(padding: AppSpacing.md)
    }
}

// MARK: - Preview

#Preview {
    ConceptCard(concept: Concept.mockConcepts[0])
        .frame(width: 170)
        .appScreenPadding()
        .appScreenBackground()
}
