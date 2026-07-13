import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline)
            .foregroundStyle(AppColor.Text.onButton)
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

struct ThemedPrimaryButtonStyle: ButtonStyle {
    let colors: ThemeColors
    let theme: AppTheme

    private var fill: Color {
        theme == .midnightFilm ? colors.accent : colors.primary
    }

    private var pressedFill: Color {
        theme == .midnightFilm ? colors.accentButtonPressed : colors.accentPressed
    }

    private var labelColor: Color {
        theme == .midnightFilm ? colors.onHighlight : colors.onAccent
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline)
            .foregroundStyle(labelColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                configuration.isPressed ? pressedFill : fill,
                in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
            )
            .shadow(color: colors.shadowSubtle, radius: 2, x: 0, y: 1)
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

#Preview("Primary · Midnight Film") {
    Button {} label: {
        Label("사진 찍기", systemImage: "camera.fill")
    }
    .buttonStyle(PrimaryButtonStyle())
    .padding()
    .background(AppTheme.midnightFilm.definition.colors.background)
    .preferredColorScheme(.dark)
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
    Button("게스트로 둘러보기") {}
        .buttonStyle(SecondaryButtonStyle())
        .padding()
        .appScreenBackground()
        .preferredColorScheme(.light)
}

#Preview("Secondary · Dark") {
    Button("게스트로 둘러보기") {}
        .buttonStyle(SecondaryButtonStyle())
        .padding()
        .appScreenBackground()
        .preferredColorScheme(.dark)
}
