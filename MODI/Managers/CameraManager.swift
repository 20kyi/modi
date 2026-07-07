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

    enum FlashMode: CaseIterable {
        case off
        case auto
        case on

        var avFlashMode: AVCaptureDevice.FlashMode {
            switch self {
            case .off: .off
            case .auto: .auto
            case .on: .on
            }
        }

        var iconName: String {
            switch self {
            case .off: "bolt.slash.fill"
            case .auto: "bolt.badge.automatic.fill"
            case .on: "bolt.fill"
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .off: "플래시 끔"
            case .auto: "플래시 자동"
            case .on: "플래시 켬"
            }
        }

        func next() -> FlashMode {
            let all = Self.allCases
            let index = all.firstIndex(of: self) ?? 0
            return all[(index + 1) % all.count]
        }
    }

    private(set) var authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    private(set) var isSessionRunning = false
    private(set) var isCapturing = false
    private(set) var setupError: CameraError?
    private(set) var zoomFactor: CGFloat = 1.0
    private(set) var minZoomFactor: CGFloat = 1.0
    private(set) var maxZoomFactor: CGFloat = 1.0
    private(set) var isFlashAvailable = false

    var flashMode: FlashMode = .auto

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.modi.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var captureDevice: AVCaptureDevice?
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
                    } else {
                        self.refreshDeviceCapabilities()
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

    // MARK: - Zoom

    func setZoomFactor(_ factor: CGFloat) {
        let clamped = min(max(factor, minZoomFactor), maxZoomFactor)
        zoomFactor = clamped

        sessionQueue.async { [weak self] in
            guard let device = self?.captureDevice else { return }

            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = clamped
                device.unlockForConfiguration()
            } catch {
                // 줌 적용 실패 시 UI 상태는 유지합니다.
            }
        }
    }

    // MARK: - Flash

    func cycleFlashMode() {
        guard isFlashAvailable else { return }

        var nextMode = flashMode.next()
        while !photoOutput.supportedFlashModes.contains(nextMode.avFlashMode) {
            nextMode = nextMode.next()
            if nextMode == flashMode { break }
        }

        if photoOutput.supportedFlashModes.contains(nextMode.avFlashMode) {
            flashMode = nextMode
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
                if self.photoOutput.supportedFlashModes.contains(self.flashMode.avFlashMode) {
                    settings.flashMode = self.flashMode.avFlashMode
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
        captureDevice = device

        guard session.canAddOutput(photoOutput) else { return }

        photoOutput.isHighResolutionCaptureEnabled = true
        session.addOutput(photoOutput)
    }

    private func refreshDeviceCapabilities() {
        guard let device = captureDevice else { return }

        minZoomFactor = device.minAvailableVideoZoomFactor
        maxZoomFactor = device.maxAvailableVideoZoomFactor
        zoomFactor = device.videoZoomFactor

        isFlashAvailable = device.hasFlash
            && photoOutput.supportedFlashModes.contains(.off)

        if isFlashAvailable, !photoOutput.supportedFlashModes.contains(flashMode.avFlashMode) {
            flashMode = photoOutput.supportedFlashModes.contains(.auto) ? .auto : .off
        }
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
