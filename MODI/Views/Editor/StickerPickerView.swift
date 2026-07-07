import SwiftUI

// MARK: - StickerPickerView

/// 하단 툴바에 표시되는 스티커 선택 패널.
struct StickerPickerView: View {

    let stickers: [String]
    var onSelect: (String) -> Void

    init(
        stickers: [String] = EditorSticker.catalog,
        onSelect: @escaping (String) -> Void
    ) {
        self.stickers = stickers
        self.onSelect = onSelect
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(stickers, id: \.self) { sticker in
                    Button {
                        onSelect(sticker)
                    } label: {
                        Text(sticker)
                            .font(.system(size: 32))
                            .frame(width: 56, height: 56)
                            .background(
                                AppColor.Background.secondary,
                                in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                    .strokeBorder(AppColor.Border.default, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("스티커 \(sticker)")
                }
            }
        }
    }
}

#Preview {
    StickerPickerView { _ in }
        .padding()
        .appScreenBackground()
}
