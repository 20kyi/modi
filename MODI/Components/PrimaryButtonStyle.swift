import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline)
            .foregroundStyle(AppColor.Text.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                configuration.isPressed ? AppColor.Accent.buttonPressed : AppColor.Accent.buttonFill,
                in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
            )
            .appShadow(.subtle)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct ThemeButtonStyle: ButtonStyle {
    let palette: AppColor.ThemePalette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline)
            .foregroundStyle(palette.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                configuration.isPressed ? palette.pressed : palette.accent,
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
            .foregroundStyle(AppColor.Accent.buttonLabel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                AppColor.Accent.buttonSoft,
                in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

#Preview("Theme · Light") {
    let palette = AppColor.themePalette(from: "F8DDE8")

    return Button("기록하기") {}
        .buttonStyle(ThemeButtonStyle(palette: palette))
        .padding()
        .appScreenBackground()
        .preferredColorScheme(.light)
}

#Preview("Primary · Light") {
    Button("기록하기") {}
        .buttonStyle(PrimaryButtonStyle())
        .padding()
        .appScreenBackground()
        .preferredColorScheme(.light)
}

#Preview("Primary · Dark") {
    Button("기록하기") {}
        .buttonStyle(PrimaryButtonStyle())
        .padding()
        .appScreenBackground()
        .preferredColorScheme(.dark)
}

#Preview("Secondary · Light") {
    Button("나중에 둘러보기") {}
        .buttonStyle(SecondaryButtonStyle())
        .padding()
        .appScreenBackground()
        .preferredColorScheme(.light)
}

#Preview("Secondary · Dark") {
    Button("나중에 둘러보기") {}
        .buttonStyle(SecondaryButtonStyle())
        .padding()
        .appScreenBackground()
        .preferredColorScheme(.dark)
}
