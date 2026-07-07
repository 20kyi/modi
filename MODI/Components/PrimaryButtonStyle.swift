import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline)
            .foregroundStyle(AppColor.Text.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                configuration.isPressed ? AppColor.Accent.pressed : AppColor.Accent.primary,
                in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
            )
            .appShadow(.subtle)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline)
            .foregroundStyle(AppColor.Accent.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                AppColor.Accent.soft,
                in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
