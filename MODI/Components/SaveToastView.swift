import SwiftUI

// MARK: - SaveToastView

struct SaveToastView: View {

    let toast: ToastManager.Toast

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: toast.systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColor.Semantic.success)

            Text(toast.message)
                .font(AppFont.headline)
                .foregroundStyle(AppColor.Text.primary)
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.lg)
        .background(AppColor.Surface.elevated, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(AppColor.Border.default, lineWidth: 0.75)
        }
        .appShadow(.elevated)
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
            .overlay {
                if let toast = toastManager.currentToast {
                    ZStack {
                        AppColor.Overlay.scrim.opacity(0.25)
                            .ignoresSafeArea()
                            .transition(.opacity)

                        SaveToastView(toast: toast)
                            .transition(.scale(scale: 0.88).combined(with: .opacity))
                    }
                    .allowsHitTesting(false)
                    .zIndex(1)
                }
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: toastManager.currentToast?.id)
    }
}
