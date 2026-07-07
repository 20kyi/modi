import SwiftUI

// MARK: - TextInputSheet

/// 사진 위에 추가할 텍스트를 입력한다.
struct TextInputSheet: View {

    @Binding var text: String
    var onAdd: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                TextField("텍스트를 입력하세요", text: $text, axis: .vertical)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1...3)
                    .padding(AppSpacing.md)
                    .background(
                        AppColor.Background.secondary,
                        in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    )
                    .focused($isFieldFocused)

                Text("사진 위에 드래그해서 위치를 바꿀 수 있어요")
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.tertiary)

                Spacer()
            }
            .padding(AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.lg)
            .appScreenBackground()
            .navigationTitle("텍스트 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundStyle(AppColor.Text.secondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onAdd(trimmed)
                        text = ""
                        dismiss()
                    }
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Accent.primary)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                isFieldFocused = true
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    TextInputSheet(text: .constant("")) { _ in }
}
