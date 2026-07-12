import SwiftUI

// MARK: - SaveToastView

struct SaveToastView: View {

    let toast: ToastManager.Toast

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: toast.systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColor.Semantic.success)

            Text(toast.message)
                .font(AppFont.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.Text.primary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(AppColor.Surface.elevated, in: Capsule())
        .overlay {
            Capsule()
                .stroke(AppColor.Border.default, lineWidth: 0.75)
        }
        .appShadow(.medium)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(toast.message)
    }
}

// MARK: - Toast Overlay

extension View {

    func appToastOverlay() -> some View {
        modifier(ToastOverlayModifier())
    }
}

private struct ToastOverlayModifier: ViewModifier {

    func body(content: Content) -> some View {
        @Bindable var toastManager = ToastManager.shared

        return content
            .overlay(alignment: .top) {
                if let toast = toastManager.currentToast {
                    SaveToastView(toast: toast)
                        .padding(.top, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .allowsHitTesting(false)
                        .zIndex(1)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.86), value: toastManager.currentToast?.id)
    }
}
