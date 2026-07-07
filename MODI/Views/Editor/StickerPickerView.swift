import SwiftUI

// MARK: - StickerPickerView

/// 스티커 목록에서 선택해 캔버스에 추가한다.
struct StickerPickerView: View {

    let stickers: [String]
    var onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    init(
        stickers: [String] = EditorSticker.catalog,
        onSelect: @escaping (String) -> Void
    ) {
        self.stickers = stickers
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 72), spacing: AppSpacing.md)
                    ],
                    spacing: AppSpacing.md
                ) {
                    ForEach(stickers, id: \.self) { sticker in
                        Button {
                            onSelect(sticker)
                            dismiss()
                        } label: {
                            Text(sticker)
                                .font(.system(size: 40))
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                                .background(
                                    AppColor.Background.secondary,
                                    in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                                        .strokeBorder(AppColor.Border.subtle, lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppSpacing.screenHorizontal)
                .padding(.vertical, AppSpacing.lg)
            }
            .appScreenBackground()
            .navigationTitle("스티커")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundStyle(AppColor.Text.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    StickerPickerView { _ in }
}
