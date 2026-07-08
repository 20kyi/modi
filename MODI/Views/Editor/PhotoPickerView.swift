import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

// MARK: - PhotoPickerView

/// SwiftUI PhotosPicker로 앨범에서 사진을 선택한다.
struct PhotoPickerView<Label: View>: View {

    @Binding var selection: PhotosPickerItem?
    var matching: PHPickerFilter = .images
    @ViewBuilder var label: () -> Label

    var body: some View {
        PhotosPicker(selection: $selection, matching: matching) {
            label()
        }
    }
}

// MARK: - Photo Picker Loader

enum PhotoPickerLoader {

    @MainActor
    static func loadImage(from item: PhotosPickerItem?) async -> UIImage? {
        guard let item else { return nil }

        if let image = try? await item.loadTransferable(type: PickedPhotoImage.self) {
            return image.uiImage
        }

        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            return image
        }

        return nil
    }
}

// MARK: - Picked Photo Transferable

private struct PickedPhotoImage: Transferable {
    let uiImage: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let image = UIImage(data: data) else {
                throw PickedPhotoImageError.importFailed
            }
            return PickedPhotoImage(uiImage: image)
        }
    }
}

private enum PickedPhotoImageError: Error {
    case importFailed
}

// MARK: - Album Photo Picker Sheet

/// 앨범 선택 전용 시트. 선택 후 이미지를 콜백으로 전달한다.
struct AlbumPhotoPickerSheet: View {

    var onImagePicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColor.Accent.primary)

                VStack(spacing: AppSpacing.sm) {
                    Text("앨범에서 사진 선택")
                        .font(AppFont.title3)
                        .foregroundStyle(AppColor.Text.primary)

                    Text("꾸미고 싶은 사진을 골라 MODI 기록으로 남겨보세요")
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                        .multilineTextAlignment(.center)
                }

                PhotoPickerView(selection: $selectedItem) {
                    Label("사진 선택", systemImage: "photo.fill")
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.Text.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColor.Accent.primary, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.xxxl)
            .appScreenBackground()
            .navigationTitle("앨범")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundStyle(AppColor.Text.secondary)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    guard let image = await PhotoPickerLoader.loadImage(from: newItem) else { return }
                    dismiss()
                    onImagePicked(image)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    AlbumPhotoPickerSheet { _ in }
}
