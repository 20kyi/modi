import PhotosUI
import SwiftUI
import UIKit

// MARK: - ImagePicker

struct ImagePicker: UIViewControllerRepresentable {

    enum Source {
        case camera
        case photoLibrary

        var uiSourceType: UIImagePickerController.SourceType {
            switch self {
            case .camera: .camera
            case .photoLibrary: .photoLibrary
            }
        }

        static var preferredCamera: Source {
            UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        }
    }

    let source: Source
    let onImagePicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = source.uiSourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            parent.dismiss()

            guard let image else { return }

            DispatchQueue.main.async { [parent] in
                parent.onImagePicked(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - PhotoLibraryPicker

/// PHPicker 기반 앨범 선택. 사진 라이브러리 권한 없이 안정적으로 동작합니다.
struct PhotoLibraryPicker: UIViewControllerRepresentable {

    let onImagePicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker

        init(parent: PhotoLibraryPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { [parent] image, _ in
                guard let image = image as? UIImage else { return }
                DispatchQueue.main.async {
                    parent.onImagePicked(image)
                }
            }
        }
    }
}
