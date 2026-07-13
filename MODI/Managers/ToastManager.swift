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
        let iconColor: Color
    }

    private(set) var currentToast: Toast?
    private var dismissTask: Task<Void, Never>?

    func showRecordSaved() {
        show(
            message: "기록이 저장됐어요",
            systemImage: "checkmark.circle.fill",
            iconColor: AppColor.Semantic.success
        )
    }

    func showRecordUpdated() {
        show(
            message: "기록이 수정됐어요",
            systemImage: "pencil.circle.fill",
            iconColor: AppColor.Accent.highlight
        )
    }

    func showRecordDeleted() {
        show(
            message: "기록이 삭제됐어요",
            systemImage: "trash.circle.fill",
            iconColor: AppColor.Semantic.error
        )
    }

    func show(
        message: String,
        systemImage: String = "checkmark.circle.fill",
        iconColor: Color = AppColor.Semantic.success,
        duration: TimeInterval = 2.0
    ) {
        dismissTask?.cancel()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
            currentToast = Toast(
                message: message,
                systemImage: systemImage,
                iconColor: iconColor
            )
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
