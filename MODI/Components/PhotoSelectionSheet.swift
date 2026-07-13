import SwiftUI
import UIKit

// MARK: - Crop Presentation

private struct PhotoCropPresentation: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - PhotoSelectionSheet

/// 갤러리 사진 선택을 안내하는 MODI 스타일 바텀시트.
struct PhotoSelectionSheet: View {

    var concept: Concept?
    var dateLabel: String?
    var showsBackButton: Bool = false
    var onImagePicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showImagePicker = false
    @State private var cropPresentation: PhotoCropPresentation?

    private var conceptThemeColor: Color {
        if let concept {
            return Color(hex: concept.themeColorHex)
        }
        return AppColor.Accent.soft
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                heroSection

                if let concept {
                    selectedConceptCard(concept)
                }

                Spacer(minLength: AppSpacing.sm)

                Button {
                    showImagePicker = true
                } label: {
                    Label("갤러리에서 사진 선택", systemImage: "photo.on.rectangle.angled")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .appScreenPadding()
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
            .appScreenBackground()
            .navigationTitle("사진 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsBackButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .accessibilityLabel("뒤로가기")
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("닫기") {
                            dismiss()
                        }
                        .foregroundStyle(AppColor.Text.secondary)
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                PhotoLibraryPicker { image in
                    showImagePicker = false
                    cropPresentation = PhotoCropPresentation(image: image)
                }
                .ignoresSafeArea()
            }
            .fullScreenCover(item: $cropPresentation) { presentation in
                SquareImageCropView(
                    image: presentation.image,
                    onConfirm: { croppedImage in
                        cropPresentation = nil
                        dismiss()
                        onImagePicked(croppedImage)
                    },
                    onCancel: {
                        cropPresentation = nil
                    }
                )
            }
        }
        .presentationDetents([.fraction(0.55)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(conceptThemeColor)
                .frame(width: 88, height: 88)
                .overlay {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(AppColor.Accent.highlight.opacity(0.55))
                }
                .appShadow(.medium)

            VStack(spacing: AppSpacing.xs) {
                if let dateLabel {
                    Text(dateLabel)
                        .font(AppFont.title3)
                        .foregroundStyle(AppColor.Text.primary)
                }

                Text(heroMessage)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.Text.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var heroMessage: String {
        if concept != nil {
            return "선택한 컨셉에 담을 사진을 1:1 비율로 맞춰보세요"
        }
        return "꾸미고 싶은 사진을 1:1 비율로 맞춰 MODI 기록으로 남겨보세요"
    }

    private func selectedConceptCard(_ concept: Concept) -> some View {
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
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Text.primary)

                Text(concept.description)
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .appCardStyle()
    }
}

// MARK: - Preview

#Preview("With Concept") {
    PhotoSelectionSheet(
        concept: .mock,
        dateLabel: "2026년 7월 5일"
    ) { _ in }
}

#Preview("Without Concept") {
    PhotoSelectionSheet { _ in }
}
