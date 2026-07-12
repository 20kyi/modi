import SwiftUI
import UIKit

// MARK: - ShareSheet

/// 렌더링된 이미지 등을 iOS 공유 시트로 전달합니다.
struct ShareSheet: UIViewControllerRepresentable {

    let items: [Any]
    var onCompleted: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.completionWithItemsHandler = { _, completed, _, _ in
            guard completed else { return }
            Task { @MainActor in
                onCompleted?()
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Share Payload

struct CollectionSharePayload: Identifiable {
    let id = UUID()
    let collection: MODICollection
    let records: [MODIRecord]
}
