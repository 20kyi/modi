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
    @Environment(MODIRepository.self) private var repository

    @State private var cameraManager = CameraManager()
    @State private var editorPresentation: CameraEditorPresentation?
    @State private var captureErrorMessage: String?

    private var themeColor: Color {
        Color(hex: concept.themeColorHex)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                missionHeader
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.lg)

                cameraSection
                    .padding(.horizontal, AppSpacing.screenHorizontal)

                captureControls
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xxxl)
            }
            .background(AppColor.Background.primary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppColor.Text.primary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("촬영")
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.Text.primary)
                }
            }
            .toolbarBackground(AppColor.Background.primary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                await cameraManager.setup()
            }
            .onDisappear {
                cameraManager.stopSession()
            }
            .fullScreenCover(item: $editorPresentation) { presentation in
                PhotoEditorView(
                    image: presentation.image,
                    mission: mission,
                    onSaved: {
                        onSaved()
                        dismiss()
                    },
                    onSaveFailed: { error in
                        onSaveFailed?(error)
                    }
                )
            }
            .alert("사진을 촬영하지 못했어요", isPresented: captureErrorIsPresented) {
                Button("확인", role: .cancel) {
                    captureErrorMessage = nil
                }
            } message: {
                Text(captureErrorMessage ?? "다시 시도해 주세요.")
            }
        }
    }

    // MARK: - Mission Header

    private var missionHeader: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("오늘의 미션")
                .font(AppFont.caption1)
                .foregroundStyle(AppColor.Text.tertiary)

            Text(concept.emoji)
                .font(.system(size: 44))

            Text(concept.title)
                .font(AppFont.title3)
                .foregroundStyle(AppColor.Text.primary)
                .multilineTextAlignment(.center)

            Text(concept.description)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.Text.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            themeColor.opacity(0.45),
            in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .strokeBorder(themeColor.opacity(0.6), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(concept.title), \(concept.description)")
    }

    // MARK: - Camera Section

    @ViewBuilder
    private var cameraSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(Color.black)

            if cameraManager.isSessionRunning {
                CameraPreview(session: cameraManager.session)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            } else {
                cameraUnavailableContent
            }
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .appShadow(.medium)
    }

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
                    .strokeBorder(AppColor.Accent.primary.opacity(0.25), lineWidth: 4)
                    .frame(width: 76, height: 76)

                Circle()
                    .fill(AppColor.Accent.primary)
                    .frame(width: 62, height: 62)
                    .opacity(cameraManager.isCapturing ? 0.6 : 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppSpacing.minTouchTarget)
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
    let (container, repository) = MODIPreviewData.makeRepository()
    return CameraView(
        todayMission: .mock,
        concept: .mock,
        mission: .mock,
        onSaved: {}
    )
    .modelContainer(container)
    .environment(repository)
}
