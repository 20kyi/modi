import AVKit
import SwiftUI

// MARK: - CollectionShareOptionsSheet

/// 컬렉션 공유 카드(이미지)와 영상 중 선택해 미리보기·저장·공유할 수 있습니다.
struct CollectionShareOptionsSheet: View {

    let collection: MODICollection
    let records: [MODIRecord]

    @Environment(\.dismiss) private var dismiss

    @State private var format: ShareFormat = .image
    @State private var shareImage: UIImage?
    @State private var videoURL: URL?
    @State private var player: AVQueuePlayer?
    @State private var playerLooper: AVPlayerLooper?
    @State private var isGeneratingVideo = false
    @State private var showShareSheet = false
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var saveErrorMessage: String?
    @State private var videoErrorMessage: String?

    private enum ShareFormat: String, CaseIterable, Identifiable {
        case image
        case video

        var id: String { rawValue }

        var label: String {
            switch self {
            case .image: "이미지"
            case .video: "영상"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                Picker("공유 형식", selection: $format) {
                    ForEach(ShareFormat.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
                .onChange(of: format) { _, newFormat in
                    if newFormat == .video {
                        prepareVideoIfNeeded()
                    } else {
                        pauseVideo()
                    }
                }

                previewSection
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                actionButtons
            }
            .appScreenBackground()
            .navigationTitle("컬렉션 공유")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            shareImage = CollectionShareCardView.renderedImage(
                for: collection,
                records: records
            )
        }
        .onDisappear {
            cleanupVideo()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems) {
                HapticManager.shared.success()
            }
        }
        .alert("저장 완료", isPresented: $saveSuccess) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(saveSuccessMessage)
        }
        .alert("저장 실패", isPresented: saveErrorIsPresented) {
            Button("확인", role: .cancel) {
                saveErrorMessage = nil
            }
        } message: {
            Text(saveErrorMessage ?? "저장에 실패했어요.")
        }
        .alert("영상 생성 실패", isPresented: videoErrorAlertIsPresented) {
            Button("확인", role: .cancel) {
                videoErrorMessage = nil
            }
        } message: {
            Text(videoErrorMessage ?? "영상을 만들지 못했어요.")
        }
        .overlay {
            if isSaving {
                ProgressView("저장 중…")
                    .padding(AppSpacing.xl)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.md))
            }
        }
    }

    // MARK: - Preview

    @ViewBuilder
    private var previewSection: some View {
        switch format {
        case .image:
            if let shareImage {
                Image(uiImage: shareImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                    .appShadow(.medium)
                    .padding(.horizontal, AppSpacing.xxl)
            } else {
                ProgressView("이미지 준비 중…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

        case .video:
            if isGeneratingVideo {
                VideoGenerationProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                    .appShadow(.medium)
                    .padding(.horizontal, AppSpacing.xxl)
            } else {
                Group {
                    if let player {
                        VideoPlayer(player: player)
                    } else {
                        ContentUnavailableView(
                            "영상을 만들 수 없어요",
                            systemImage: "film",
                            description: Text("다시 시도해 주세요.")
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(9 / 16, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                .appShadow(.medium)
                .padding(.horizontal, AppSpacing.xxl)
            }
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: AppSpacing.md) {
            Button {
                saveCurrentFormat()
            } label: {
                Label("사진 앱에 저장", systemImage: "square.and.arrow.down")
                    .font(AppFont.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.Accent.buttonLabel)
            .disabled(isSaving || !canSaveOrShare)

            Button {
                showShareSheet = true
            } label: {
                Label("공유하기", systemImage: "square.and.arrow.up")
                    .font(AppFont.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(AppColor.Accent.buttonLabel)
            .disabled(!canSaveOrShare)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.bottom, AppSpacing.xxxl)
    }

    private var canSaveOrShare: Bool {
        switch format {
        case .image:
            shareImage != nil
        case .video:
            videoURL != nil && !isGeneratingVideo
        }
    }

    private var shareItems: [Any] {
        switch format {
        case .image:
            shareImage.map { [$0] } ?? []
        case .video:
            videoURL.map { [$0] } ?? []
        }
    }

    private var saveSuccessMessage: String {
        format == .image
            ? "컬렉션 카드가 사진 앱에 저장됐어요."
            : "컬렉션 영상이 사진 앱에 저장됐어요."
    }

    private var saveErrorIsPresented: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }

    private var videoErrorAlertIsPresented: Binding<Bool> {
        Binding(
            get: { videoErrorMessage != nil },
            set: { if !$0 { videoErrorMessage = nil } }
        )
    }

    private func prepareVideoIfNeeded() {
        guard videoURL == nil, !isGeneratingVideo else { return }

        isGeneratingVideo = true

        Task { @MainActor in
            do {
                let url = try await CollectionShareVideoRenderer.render(
                    collection: collection,
                    records: records
                )
                videoURL = url
                startLoopingPlayer(with: url)
            } catch {
                videoErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }

            isGeneratingVideo = false
        }
    }

    private func startLoopingPlayer(with url: URL) {
        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        player = queuePlayer
        queuePlayer.play()
    }

    private func pauseVideo() {
        player?.pause()
    }

    private func cleanupVideo() {
        player?.pause()
        playerLooper = nil
        player = nil
        if let videoURL {
            try? FileManager.default.removeItem(at: videoURL)
        }
    }

    private func saveCurrentFormat() {
        isSaving = true

        Task {
            do {
                switch format {
                case .image:
                    guard let shareImage else {
                        throw PhotoLibrarySaver.SaveError.saveFailed
                    }
                    try await PhotoLibrarySaver.saveImage(shareImage)

                case .video:
                    guard let videoURL else {
                        throw PhotoLibrarySaver.SaveError.videoSaveFailed
                    }
                    try await PhotoLibrarySaver.saveVideo(at: videoURL)
                }

                isSaving = false
                saveSuccess = true
                HapticManager.shared.success()
            } catch {
                isSaving = false
                saveErrorMessage = error.localizedDescription
            }
        }
    }
}
