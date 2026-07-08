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

    var body: some View {
        PhotoSelectionSheet(onImagePicked: onImagePicked)
    }
}

#Preview {
    AlbumPhotoPickerSheet { _ in }
}
