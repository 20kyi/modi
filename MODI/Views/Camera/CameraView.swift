import SwiftData
import SwiftUI

// MARK: - Editor Presentation

private struct CameraEditorPresentation: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - CameraView

/// 오늘의 미션과 연결된 카메라 촬영 화면.
struct CameraView: View {

    let todayMission: TodayMission
    let concept: Concept
    let mission: DailyMission
    var onSaved: () -> Void
    var onSaveFailed: ((Error) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @Environment(RecordRepository.self) private var repository
    @Environment(StreakManager.self) private var streakManager

    @State private var cameraManager = CameraManager()
    @State private var editorPresentation: CameraEditorPresentation?
    @State private var captureErrorMessage: String?
    @State private var pinchBaseZoom: CGFloat = 1.0
    @State private var viewfinderSide: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let side = viewfinderDimension(in: geometry.size)

            ZStack {
                AppColor.Surface.cameraBackdrop
                    .ignoresSafeArea()

                VStack(spacing: AppSpacing.lg) {
                    topBar

                    Spacer(minLength: AppSpacing.md)

                    squareViewfinder(side: side)

                    missionOverlay
                        .padding(.horizontal, AppSpacing.sm)

                    Spacer(minLength: AppSpacing.md)

                    VStack(spacing: AppSpacing.md) {
                        if cameraManager.zoomFactor > 1.05 {
                            zoomIndicator
                        }

                        captureControls
                    }
                    .padding(.bottom, AppSpacing.huge)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
            }
            .onAppear {
                viewfinderSide = side
            }
            .onChange(of: geometry.size) { _, newSize in
                viewfinderSide = viewfinderDimension(in: newSize)
            }
        }
        .background(AppColor.Surface.cameraBackdrop)
        .task {
            await cameraManager.setup()
        }
        .onChange(of: cameraManager.isSessionRunning) { _, isRunning in
            if isRunning {
                pinchBaseZoom = cameraManager.zoomFactor
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .fullScreenCover(item: $editorPresentation) { presentation in
            PhotoEditorView(
                image: presentation.image,
                concept: concept,
                onSaved: {
                    onSaved()
                    dismiss()
                },
                onSaveFailed: { error in
                    onSaveFailed?(error)
                }
            )
            .environment(repository)
            .environment(streakManager)
        }
        .alert("사진을 촬영하지 못했어요", isPresented: captureErrorIsPresented) {
            Button("확인", role: .cancel) {
                captureErrorMessage = nil
            }
        } message: {
            Text(captureErrorMessage ?? "다시 시도해 주세요.")
        }
    }

    // MARK: - Square Viewfinder

    private func viewfinderDimension(in containerSize: CGSize) -> CGFloat {
        let horizontalPadding = AppSpacing.screenHorizontal * 2
        let maxWidth = max(containerSize.width - horizontalPadding, 1)
        let reservedHeight = AppSpacing.huge * 4 + AppSpacing.xxxl
        let maxHeight = max(containerSize.height - reservedHeight, 1)
        return min(maxWidth, maxHeight)
    }

    @ViewBuilder
    private func squareViewfinder(side: CGFloat) -> some View {
        ZStack {
            if cameraManager.isSessionRunning {
                CameraPreview(session: cameraManager.session)
            } else {
                AppColor.Surface.cameraBackdrop
                    .overlay {
                        cameraUnavailableContent
                    }
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(AppColor.Text.onAccent.opacity(0.35), lineWidth: 1)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(zoomGesture)
        .accessibilityLabel("1대1 카메라 미리보기")
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.Text.onAccent)
                    .frame(width: AppSpacing.minTouchTarget, height: AppSpacing.minTouchTarget)
                    .background(AppColor.Overlay.scrim.opacity(0.65), in: Circle())
            }
            .accessibilityLabel("닫기")

            Spacer()

            if cameraManager.isFlashAvailable {
                Button {
                    cameraManager.cycleFlashMode()
                } label: {
                    Image(systemName: cameraManager.flashMode.iconName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColor.Text.onAccent)
                        .frame(width: AppSpacing.minTouchTarget, height: AppSpacing.minTouchTarget)
                        .background(AppColor.Overlay.scrim.opacity(0.65), in: Circle())
                }
                .accessibilityLabel(cameraManager.flashMode.accessibilityLabel)
            }
        }
        .padding(.top, AppSpacing.sm)
    }

    private var zoomIndicator: some View {
        Text(String(format: "%.1f×", cameraManager.zoomFactor))
            .font(AppFont.footnote)
            .foregroundStyle(AppColor.Text.onAccent)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColor.Overlay.scrim.opacity(0.8), in: Capsule())
            .accessibilityLabel("줌 \(String(format: "%.1f", cameraManager.zoomFactor))배")
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                guard cameraManager.isSessionRunning else { return }
                cameraManager.setZoomFactor(pinchBaseZoom * value)
            }
            .onEnded { _ in
                pinchBaseZoom = cameraManager.zoomFactor
            }
    }

    // MARK: - Mission Overlay

    private var missionOverlay: some View {
        VStack(spacing: AppSpacing.md) {
            Text(concept.emoji)
                .font(.system(size: 56))
                .shadow(color: AppColor.Overlay.scrim.opacity(0.85), radius: 8, y: 2)

            Text(concept.title)
                .font(AppFont.title2)
                .foregroundStyle(AppColor.Text.onAccent)
                .multilineTextAlignment(.center)
                .shadow(color: AppColor.Overlay.scrim.opacity(0.9), radius: 6, y: 2)

            Text(concept.description)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.Text.onAccent.opacity(0.9))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: AppColor.Overlay.scrim.opacity(0.85), radius: 6, y: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(concept.title), \(concept.description)")
    }

    // MARK: - Unavailable State

    @ViewBuilder
    private var cameraUnavailableContent: some View {
        VStack(spacing: AppSpacing.md) {
            if cameraManager.setupError == .notAuthorized {
                Image(systemName: "camera.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppColor.Text.onAccent.opacity(0.8))

                Text("카메라 접근 권한이 필요해요")
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Text.onAccent)

                Text("설정에서 MODI의 카메라 접근을 허용해 주세요.")
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.onAccent.opacity(0.75))
                    .multilineTextAlignment(.center)

                Button("설정 열기") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(url)
                }
                .font(AppFont.footnote)
                .foregroundStyle(AppColor.Text.onAccent)
                .padding(.top, AppSpacing.xs)
            } else {
                ProgressView()
                    .tint(AppColor.Text.onAccent)

                Text(cameraStatusMessage)
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.onAccent.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppSpacing.xl)
    }

    private var cameraStatusMessage: String {
        if let setupError = cameraManager.setupError {
            return setupError.localizedDescription
        }
        return "카메라를 준비하고 있어요"
    }

    // MARK: - Capture Controls

    private var captureControls: some View {
        Button {
            Task {
                await capturePhoto()
            }
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(AppColor.Text.onAccent.opacity(0.85), lineWidth: 4)
                    .frame(width: 76, height: 76)

                Circle()
                    .fill(AppColor.Text.onAccent)
                    .frame(width: 62, height: 62)
                    .opacity(cameraManager.isCapturing ? 0.6 : 1)
            }
            .shadow(color: AppColor.Overlay.scrim.opacity(0.8), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!cameraManager.isSessionRunning || cameraManager.isCapturing)
        .accessibilityLabel("사진 촬영")
    }

    // MARK: - Actions

    private func capturePhoto() async {
        do {
            let image = try await cameraManager.capturePhoto()
            let viewport = CGSize(width: viewfinderSide, height: viewfinderSide)
            let cropped = ImageCropUtility.cropSquareAspectFill(image: image, viewportSize: viewport) ?? image
            editorPresentation = CameraEditorPresentation(image: cropped)
        } catch {
            captureErrorMessage = error.localizedDescription
        }
    }

    private var captureErrorIsPresented: Binding<Bool> {
        Binding(
            get: { captureErrorMessage != nil },
            set: { if !$0 { captureErrorMessage = nil } }
        )
    }
}

// MARK: - Preview

#Preview("Light") {
    let (container, repository) = RecordPreviewData.makeRepository()
    return CameraView(
        todayMission: .mock,
        concept: .mock,
        mission: .mock,
        onSaved: {}
    )
    .modelContainer(container)
    .environment(repository)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    let (container, repository) = RecordPreviewData.makeRepository()
    return CameraView(
        todayMission: .mock,
        concept: .mock,
        mission: .mock,
        onSaved: {}
    )
    .modelContainer(container)
    .environment(repository)
    .preferredColorScheme(.dark)
}
