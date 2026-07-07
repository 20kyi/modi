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

    @State private var cameraManager = CameraManager()
    @State private var editorPresentation: CameraEditorPresentation?
    @State private var captureErrorMessage: String?
    @State private var pinchBaseZoom: CGFloat = 1.0

    var body: some View {
        ZStack {
            cameraBackground
                .ignoresSafeArea()

            cameraScrim
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer(minLength: AppSpacing.xxxl)

                missionOverlay

                Spacer(minLength: AppSpacing.xxxl)

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
        .background(Color.black)
        .simultaneousGesture(zoomGesture)
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
        }
        .alert("사진을 촬영하지 못했어요", isPresented: captureErrorIsPresented) {
            Button("확인", role: .cancel) {
                captureErrorMessage = nil
            }
        } message: {
            Text(captureErrorMessage ?? "다시 시도해 주세요.")
        }
    }

    // MARK: - Camera Background

    @ViewBuilder
    private var cameraBackground: some View {
        if cameraManager.isSessionRunning {
            CameraPreview(session: cameraManager.session)
        } else {
            Color.black
                .overlay {
                    cameraUnavailableContent
                }
        }
    }

    private var cameraScrim: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.45),
                    Color.black.opacity(0.15),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 220)

            Spacer()

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.2),
                    Color.black.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
        }
        .allowsHitTesting(false)
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
                    .background(Color.black.opacity(0.25), in: Circle())
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
                        .background(Color.black.opacity(0.25), in: Circle())
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
            .background(Color.black.opacity(0.35), in: Capsule())
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
                .shadow(color: .black.opacity(0.35), radius: 8, y: 2)

            Text(concept.title)
                .font(AppFont.title2)
                .foregroundStyle(AppColor.Text.onAccent)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.4), radius: 6, y: 2)

            Text(concept.description)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.Text.onAccent.opacity(0.9))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
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
            .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!cameraManager.isSessionRunning || cameraManager.isCapturing)
        .accessibilityLabel("사진 촬영")
    }

    // MARK: - Actions

    private func capturePhoto() async {
        do {
            let image = try await cameraManager.capturePhoto()
            editorPresentation = CameraEditorPresentation(image: image)
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

#Preview {
    let (container, repository) = RecordPreviewData.makeRepository()
    return CameraView(
        todayMission: .mock,
        concept: .mock,
        mission: .mock,
        onSaved: {}
    )
    .modelContainer(container)
    .environment(repository)
}
