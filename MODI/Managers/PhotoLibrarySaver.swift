import Photos
import UIKit

// MARK: - PhotoLibrarySaver

enum PhotoLibrarySaver {

    enum SaveError: LocalizedError {
        case accessDenied
        case saveFailed

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                "사진 앱 접근 권한이 필요해요. 설정에서 허용해 주세요."
            case .saveFailed:
                "이미지 저장에 실패했어요. 다시 시도해 주세요."
            }
        }
    }

    @MainActor
    static func saveImage(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized else {
            throw SaveError.accessDenied
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: SaveError.saveFailed)
                }
            }
        }
    }
}
