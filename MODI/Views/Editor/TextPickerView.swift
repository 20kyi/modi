import SwiftUI

// MARK: - TextPickerView

/// 하단 툴바에 표시되는 텍스트 선택·입력 패널.
struct TextPickerView: View {

    var suggestions: [String]
    var onSelect: (String) -> Void
    var onRequestCustomInput: () -> Void

    init(
        suggestions: [String] = TextPickerView.defaultSuggestions,
        onSelect: @escaping (String) -> Void,
        onRequestCustomInput: @escaping () -> Void
    ) {
        self.suggestions = suggestions
        self.onSelect = onSelect
        self.onRequestCustomInput = onRequestCustomInput
    }

    static var defaultSuggestions: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return [
            "Cloud Hunter",
            formatter.string(from: .now),
            "오늘 발견한 순간"
        ]
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            onSelect(suggestion)
                        } label: {
                            Text(suggestion)
                                .font(AppFont.subheadline)
                                .foregroundStyle(AppColor.Text.primary)
                                .lineLimit(1)
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    AppColor.Background.secondary,
                                    in: Capsule()
                                )
                                .overlay {
                                    Capsule()
                                        .strokeBorder(AppColor.Border.default, lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                onRequestCustomInput()
            } label: {
                Label("텍스트 추가", systemImage: "plus")
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Text.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        AppColor.Background.secondary,
                        in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    )
            }
            .buttonStyle(.plain)

            Text("추가한 텍스트는 사진 위에서 드래그할 수 있어요")
                .font(AppFont.footnote)
                .foregroundStyle(AppColor.Text.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    TextPickerView(onSelect: { _ in }, onRequestCustomInput: {})
        .padding()
        .appScreenBackground()
}
