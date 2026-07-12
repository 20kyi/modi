import SwiftUI

// MARK: - ToastManager

/// 앱 전역 토스트 알림을 관리합니다.
@Observable
@MainActor
final class ToastManager {

    static let shared = ToastManager()

    struct Toast: Equatable, Identifiable {
        let id = UUID()
        let message: String
        let systemImage: String
    }

    private(set) var currentToast: Toast?
    private var dismissTask: Task<Void, Never>?

    func showRecordSaved() {
        show(message: "기록이 저장됐어요")
    }

    func show(
        message: String,
        systemImage: String = "checkmark.circle.fill",
        duration: TimeInterval = 2.0
    ) {
        dismissTask?.cancel()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
            currentToast = Toast(message: message, systemImage: systemImage)
        }

        dismissTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }

            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                currentToast = nil
            }
        }
    }
}
