import SwiftUI

struct MonthlyConceptPreviewView: View {

    let concept: MonthlyConcept

    private var sectionTitle: String {
        let month = Calendar.current.component(.month, from: Date())
        return "\(month)월의 MODI"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(sectionTitle)
                .font(AppFont.title3)
                .foregroundStyle(AppColor.Text.primary)

            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                HStack(spacing: AppSpacing.md) {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(AppColor.emojiBackground(from: concept.themeColorHex))
                        .frame(width: 56, height: 56)
                        .overlay {
                            Text(concept.emoji)
                                .font(.system(size: 28))
                        }

                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(concept.title)
                            .font(AppFont.title3)
                            .foregroundStyle(AppColor.Text.primary)

                        Text("이번 달 기록: \(concept.currentRecordCount)개")
                            .font(AppFont.footnote)
                            .foregroundStyle(AppColor.Text.secondary)
                    }
                }

                NavigationLink {
                    MonthlyMODIView()
                } label: {
                    Text("기록 보기")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .appCardStyle()
        }
    }
}

#Preview {
    MonthlyConceptPreviewView(concept: .mock)
        .appScreenPadding()
        .appScreenBackground()
}
