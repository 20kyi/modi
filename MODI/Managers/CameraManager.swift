import AVFoundation
import Observation
import UIKit

// MARK: - CameraManager

@Observable
@MainActor
final class CameraManager: NSObject {

    enum CameraError: LocalizedError {
        case unavailable
        case notAuthorized
        case configurationFailed
        case captureFailed

        var errorDescription: String? {
            switch self {
            case .unavailable:
                "이 기기에서는 카메라를 사용할 수 없어요."
            case .notAuthorized:
                "카메라 접근 권한이 필요해요. 설정에서 허용해 주세요."
            case .configurationFailed:
                "카메라를 준비하지 못했어요."
            case .captureFailed:
                "사진을 촬영하지 못했어요."
            }
        }
    }

    private(set) var authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    private(set) var isSessionRunning = false
    private(set) var isCapturing = false
    private(set) var setupError: CameraError?

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.modi.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var photoContinuation: CheckedContinuation<UIImage, Error>?

    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }

    var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    // MARK: - Permission

    func requestPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        authorizationStatus = status

        guard status == .notDetermined else { return }

        let granted = await AVCaptureDevice.requestAccess(for: .video)
        authorizationStatus = granted ? .authorized : .denied
    }

    // MARK: - Session

    func setup() async {
        await requestPermission()

        guard isCameraAvailable else {
            setupError = .unavailable
            return
        }

        guard isAuthorized else {
            setupError = .notAuthorized
            return
        }

        setupError = nil

        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }

                self.configureSessionIfNeeded()
                if !self.session.isRunning {
                    self.session.startRunning()
                }

                Task { @MainActor in
                    self.isSessionRunning = self.session.isRunning
                    if !self.session.isRunning {
                        self.setupError = .configurationFailed
                    }
                    continuation.resume()
                }
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()

            Task { @MainActor in
                self.isSessionRunning = false
            }
        }
    }

    // MARK: - Capture

    func capturePhoto() async throws -> UIImage {
        guard isAuthorized else { throw CameraError.notAuthorized }
        guard isSessionRunning else { throw CameraError.configurationFailed }
        guard !isCapturing else { throw CameraError.captureFailed }

        isCapturing = true
        defer { isCapturing = false }

        return try await withCheckedThrowingContinuation { continuation in
            photoContinuation = continuation

            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraError.captureFailed)
                    return
                }

                let settings = AVCapturePhotoSettings()
                if self.photoOutput.supportedFlashModes.contains(.auto) {
                    settings.flashMode = .auto
                }
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    // MARK: - Private

    private func configureSessionIfNeeded() {
        guard session.inputs.isEmpty else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        defer { session.commitConfiguration() }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { return }

        session.addInput(input)

        guard session.canAddOutput(photoOutput) else { return }

        photoOutput.isHighResolutionCaptureEnabled = true
        session.addOutput(photoOutput)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                photoContinuation?.resume(throwing: error)
                photoContinuation = nil
                return
            }

            guard
                let data = photo.fileDataRepresentation(),
                let image = UIImage(data: data)
            else {
                photoContinuation?.resume(throwing: CameraError.captureFailed)
                photoContinuation = nil
                return
            }

            photoContinuation?.resume(returning: image)
            photoContinuation = nil
        }
    }
}
