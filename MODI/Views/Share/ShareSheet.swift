import SwiftUI
import UIKit

// MARK: - ShareSheet

/// 렌더링된 이미지 등을 iOS 공유 시트로 전달합니다.
struct ShareSheet: UIViewControllerRepresentable {

    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Share Payload

struct ShareImagePayload: Identifiable {
    let id = UUID()
    let image: UIImage
}
