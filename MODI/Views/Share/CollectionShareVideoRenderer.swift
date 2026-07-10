import AVFoundation
import UIKit

// MARK: - CollectionShareVideoRenderer

/// 컬렉션 공유용 9:16 세로 영상을 생성합니다.
/// 상단 MODI · 중앙 2행 무한 마르키 · 하단 컬렉션 제목 구성입니다.
enum CollectionShareVideoRenderer {

    enum RenderError: LocalizedError {
        case noPhotos
        case writerSetupFailed
        case frameAppendFailed

        var errorDescription: String? {
            switch self {
            case .noPhotos:
                "공유할 사진이 없어요."
            case .writerSetupFailed:
                "영상 생성 준비에 실패했어요."
            case .frameAppendFailed:
                "영상 프레임 생성에 실패했어요."
            }
        }
    }

    private struct VideoLabels: Sendable {
        let emoji: String
        let title: String
        let badgeTitle: String?
    }

    private enum Config {
        static let videoSize = CGSize(width: 1080, height: 1920)
        static let fps: Int32 = 30
        static let scrollSpeed: CGFloat = 160
        static let photoGap: CGFloat = 24
        static let rowGap: CGFloat = 36
        static let cornerRadius: CGFloat = AppRadius.md
        static let baseRowHeights: [CGFloat] = [460, 420]
        static let heightScales: [CGFloat] = [1.0, 0.86, 1.14, 0.9, 1.1, 0.94, 1.06, 0.88, 1.12, 0.92]
        static let backgroundColor = UIColor(red: 250 / 255, green: 249 / 255, blue: 247 / 255, alpha: 1)
        static let primaryTextColor = UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)
        static let badgeTextColor = UIColor(red: 110 / 255, green: 110 / 255, blue: 115 / 255, alpha: 0.82)
        static let logoColor = UIColor(red: 174 / 255, green: 174 / 255, blue: 178 / 255, alpha: 1)
        static let visibleBounds = CGRect(origin: .zero, size: videoSize)
        static let topAreaHeight: CGFloat = 200
        static let footerAreaHeight: CGFloat = 300
    }

    private struct PhotoItem {
        let image: UIImage
        let size: CGSize
    }

    private struct RowLayout {
        let periodTile: [PhotoItem]
        let loopPeriod: CGFloat
        let centerY: CGFloat
        let maxHeight: CGFloat
    }

    private struct MarqueeLayout {
        let row1: RowLayout
        let row2: RowLayout
        let loopPeriod: CGFloat
    }

    // MARK: - Public API

    @MainActor
    static func render(
        collection: MODICollection,
        records: [MODIRecord],
        progress: (@Sendable (Double) -> Void)? = nil
    ) async throws -> URL {
        let images = records
            .sorted { $0.createdAt > $1.createdAt }
            .compactMap(\.displayImage)

        guard !images.isEmpty else {
            throw RenderError.noPhotos
        }

        let labels = VideoLabels(
            emoji: collection.emoji,
            title: collection.title,
            badgeTitle: collection.currentTitleName
        )

        return try await Task.detached(priority: .userInitiated) {
            try renderVideo(images: images, labels: labels, progress: progress)
        }.value
    }

    // MARK: - Video Generation

    private static func renderVideo(
        images: [UIImage],
        labels: VideoLabels,
        progress: (@Sendable (Double) -> Void)?
    ) throws -> URL {
        reportProgress(0, handler: progress)

        let marquee = buildMarqueeLayout(from: images)
        reportProgress(0.08, handler: progress)

        let loopDuration = TimeInterval(marquee.loopPeriod / Config.scrollSpeed)
        let totalFrames = max(2, Int(round(loopDuration * Double(Config.fps))))

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("collection-share-\(UUID().uuidString).mp4")

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Config.videoSize.width,
            AVVideoHeightKey: Config.videoSize.height
        ]

        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writerInput.expectsMediaDataInRealTime = false

        let sourceAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: Config.videoSize.width,
            kCVPixelBufferHeightKey as String: Config.videoSize.height
        ]

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: sourceAttributes
        )

        guard writer.canAdd(writerInput) else {
            throw RenderError.writerSetupFailed
        }

        writer.add(writerInput)
        guard writer.startWriting() else {
            throw RenderError.writerSetupFailed
        }

        writer.startSession(atSourceTime: .zero)

        for frameIndex in 0..<totalFrames {
            while !writerInput.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.005)
            }

            let time = CMTime(value: CMTimeValue(frameIndex), timescale: Config.fps)
            let scrollOffset = marquee.loopPeriod * CGFloat(frameIndex) / CGFloat(totalFrames)

            guard
                let pool = adaptor.pixelBufferPool,
                let pixelBuffer = makePixelBuffer(from: pool)
            else {
                throw RenderError.frameAppendFailed
            }

            CVPixelBufferLockBaseAddress(pixelBuffer, [])
            defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

            guard let context = makeDrawingContext(for: pixelBuffer) else {
                throw RenderError.frameAppendFailed
            }

            drawFrame(
                scrollOffset: scrollOffset,
                labels: labels,
                row1: marquee.row1,
                row2: marquee.row2,
                in: context
            )

            guard adaptor.append(pixelBuffer, withPresentationTime: time) else {
                throw RenderError.frameAppendFailed
            }

            let frameProgress = 0.08 + 0.87 * Double(frameIndex + 1) / Double(totalFrames)
            if frameIndex == 0 || frameIndex == totalFrames - 1 || frameIndex % 2 == 0 {
                reportProgress(frameProgress, handler: progress)
            }
        }

        writerInput.markAsFinished()
        reportProgress(0.96, handler: progress)

        let semaphore = DispatchSemaphore(value: 0)
        writer.finishWriting {
            semaphore.signal()
        }
        semaphore.wait()

        guard writer.status == .completed else {
            throw writer.error ?? RenderError.frameAppendFailed
        }

        reportProgress(1, handler: progress)
        return outputURL
    }

    private static func reportProgress(
        _ value: Double,
        handler: (@Sendable (Double) -> Void)?
    ) {
        guard let handler else { return }
        let clamped = min(max(value, 0), 1)
        DispatchQueue.main.async {
            handler(clamped)
        }
    }

    // MARK: - Layout

    private static func buildMarqueeLayout(from images: [UIImage]) -> MarqueeLayout {
        let (row1Single, row2Single, row1MaxHeight, row2MaxHeight, topY) = buildSingleRows(from: images)
        let loopPeriod = alignedLoopPeriod(row1: row1Single, row2: row2Single)

        let row1 = makeMarqueeRow(
            from: row1Single,
            loopPeriod: loopPeriod,
            centerY: topY + row1MaxHeight / 2,
            maxHeight: row1MaxHeight
        )
        let row2 = makeMarqueeRow(
            from: row2Single,
            loopPeriod: loopPeriod,
            centerY: topY + row1MaxHeight + Config.rowGap + row2MaxHeight / 2,
            maxHeight: row2MaxHeight
        )

        let finalPeriod = max(row1.loopPeriod, row2.loopPeriod, 1)
        return MarqueeLayout(row1: row1, row2: row2, loopPeriod: finalPeriod)
    }

    private static func buildSingleRows(
        from images: [UIImage]
    ) -> (row1: [PhotoItem], row2: [PhotoItem], row1MaxHeight: CGFloat, row2MaxHeight: CGFloat, topY: CGFloat) {
        var row1Items: [PhotoItem] = []
        var row2Items: [PhotoItem] = []

        for (index, image) in images.enumerated() {
            let rowIndex = index % 2
            let scale = Config.heightScales[(index / 2) % Config.heightScales.count]
            let height = Config.baseRowHeights[rowIndex] * scale
            let aspect = max(image.size.width, 1) / max(image.size.height, 1)
            let width = height * aspect
            let size = CGSize(width: width, height: height)
            let item = PhotoItem(
                image: preparedImage(from: image, targetSize: size),
                size: size
            )

            if rowIndex == 0 {
                row1Items.append(item)
            } else {
                row2Items.append(item)
            }
        }

        let row1MaxHeight = row1Items.map(\.size.height).max() ?? Config.baseRowHeights[0]
        let row2MaxHeight = row2Items.map(\.size.height).max() ?? Config.baseRowHeights[1]
        let rowsAreaHeight = row1MaxHeight + Config.rowGap + row2MaxHeight
        let photosAreaHeight = Config.videoSize.height - Config.topAreaHeight - Config.footerAreaHeight
        let topY = Config.topAreaHeight + max(0, (photosAreaHeight - rowsAreaHeight) / 2)

        return (row1Items, row2Items, row1MaxHeight, row2MaxHeight, topY)
    }

    /// 한 주기 타일 너비를 맞춥니다. 화면을 채울 만큼 넓되, 컬렉션 첫 이미지부터 시작합니다.
    private static func alignedLoopPeriod(row1: [PhotoItem], row2: [PhotoItem]) -> CGFloat {
        let minimumWidth = Config.videoSize.width

        var target = max(
            periodTileWidth(for: row1, minimumWidth: minimumWidth),
            periodTileWidth(for: row2, minimumWidth: minimumWidth)
        )

        for _ in 0..<6 {
            let period1 = periodTileWidth(for: row1, minimumWidth: target)
            let period2 = periodTileWidth(for: row2, minimumWidth: target)
            if abs(period1 - period2) < 1 {
                return max(period1, period2, 1)
            }
            target = max(period1, period2)
        }

        return max(target, 1)
    }

    private static func periodTileWidth(for single: [PhotoItem], minimumWidth: CGFloat) -> CGFloat {
        guard !single.isEmpty else { return 0 }
        return contentWidth(for: periodTile(from: single, minimumWidth: minimumWidth))
    }

    /// 컬렉션 순서를 유지한 채 화면을 채울 만큼만 반복한 1주기 타일.
    private static func periodTile(from single: [PhotoItem], minimumWidth: CGFloat) -> [PhotoItem] {
        guard !single.isEmpty else { return [] }
        let requiredWidth = max(minimumWidth, contentWidth(for: single))
        return repeatedItems(single, minimumWidth: requiredWidth)
    }

    private static func makeMarqueeRow(
        from single: [PhotoItem],
        loopPeriod: CGFloat,
        centerY: CGFloat,
        maxHeight: CGFloat
    ) -> RowLayout {
        guard !single.isEmpty else {
            return RowLayout(periodTile: [], loopPeriod: loopPeriod, centerY: centerY, maxHeight: maxHeight)
        }

        let tile = periodTile(from: single, minimumWidth: loopPeriod)
        let actualPeriod = max(contentWidth(for: tile), 1)

        return RowLayout(
            periodTile: tile,
            loopPeriod: actualPeriod,
            centerY: centerY,
            maxHeight: maxHeight
        )
    }

    private static func repeatedItems(
        _ items: [PhotoItem],
        minimumWidth: CGFloat
    ) -> [PhotoItem] {
        guard !items.isEmpty else { return [] }

        var result: [PhotoItem] = []
        while contentWidth(for: result) < minimumWidth {
            result.append(contentsOf: items)
        }
        return result
    }

    private static func contentWidth(for items: [PhotoItem]) -> CGFloat {
        guard !items.isEmpty else { return 0 }
        let widths = items.reduce(CGFloat.zero) { $0 + $1.size.width }
        let gaps = Config.photoGap * CGFloat(items.count - 1)
        return widths + gaps
    }

    // MARK: - Image Preparation

    private static func preparedImage(from image: UIImage, targetSize: CGSize) -> UIImage {
        let pixelWidth = max(1, Int(targetSize.width.rounded(.up)))
        let pixelHeight = max(1, Int(targetSize.height.rounded(.up)))
        let size = CGSize(width: pixelWidth, height: pixelHeight)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Drawing

    private static func drawFrame(
        scrollOffset: CGFloat,
        labels: VideoLabels,
        row1: RowLayout,
        row2: RowLayout,
        in context: CGContext
    ) {
        context.setFillColor(Config.backgroundColor.cgColor)
        context.fill(Config.visibleBounds)

        UIGraphicsPushContext(context)
        defer { UIGraphicsPopContext() }

        drawTopLogo(in: context)
        drawFooter(labels, in: context)

        drawRow(row1, scrollOffset: scrollOffset, in: context)
        drawRow(row2, scrollOffset: scrollOffset, in: context)
    }

    private static func drawTopLogo(in context: CGContext) {
        let fontSize: CGFloat = 48
        let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        let roundedDescriptor = font.fontDescriptor.withDesign(.rounded) ?? font.fontDescriptor
        let roundedFont = UIFont(descriptor: roundedDescriptor, size: fontSize)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: roundedFont,
            .foregroundColor: Config.logoColor,
            .kern: 4.8
        ]

        let text = NSAttributedString(string: "MODI", attributes: attributes)
        let textSize = text.size()
        let origin = CGPoint(
            x: (Config.videoSize.width - textSize.width) / 2,
            y: 108
        )
        text.draw(at: origin)
    }

    private static func drawFooter(_ labels: VideoLabels, in context: CGContext) {
        let footerTop = Config.videoSize.height - Config.footerAreaHeight + 40
        let centerX = Config.videoSize.width / 2

        let emojiFont = UIFont.systemFont(ofSize: 64)
        let emoji = NSAttributedString(
            string: labels.emoji,
            attributes: [.font: emojiFont]
        )
        let emojiSize = emoji.size()
        emoji.draw(at: CGPoint(x: centerX - emojiSize.width / 2, y: footerTop))

        let titleFont = UIFont.systemFont(ofSize: 52, weight: .bold)
        let titleDescriptor = titleFont.fontDescriptor.withDesign(.rounded) ?? titleFont.fontDescriptor
        let roundedTitleFont = UIFont(descriptor: titleDescriptor, size: 52)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 8
        paragraph.lineBreakMode = .byWordWrapping

        let attributedTitle = NSAttributedString(
            string: labels.title,
            attributes: [
                .font: roundedTitleFont,
                .foregroundColor: Config.primaryTextColor,
                .paragraphStyle: paragraph
            ]
        )

        let titleTop = footerTop + emojiSize.height + 16
        let footerRect = CGRect(
            x: 72,
            y: titleTop,
            width: Config.videoSize.width - 144,
            height: Config.footerAreaHeight - (titleTop - footerTop) - 32
        )
        attributedTitle.draw(in: footerRect)

        guard let badgeTitle = labels.badgeTitle, !badgeTitle.isEmpty else { return }

        let titleHeight = attributedTitle.boundingRect(
            with: footerRect.size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height

        let badgeFont = UIFont.systemFont(ofSize: 30, weight: .medium)
        let badgeDescriptor = badgeFont.fontDescriptor.withDesign(.rounded) ?? badgeFont.fontDescriptor
        let roundedBadgeFont = UIFont(descriptor: badgeDescriptor, size: 30)

        let badgeParagraph = NSMutableParagraphStyle()
        badgeParagraph.alignment = .center

        let attributedBadge = NSAttributedString(
            string: badgeTitle,
            attributes: [
                .font: roundedBadgeFont,
                .foregroundColor: Config.badgeTextColor,
                .paragraphStyle: badgeParagraph
            ]
        )

        let badgeRect = CGRect(
            x: 72,
            y: titleTop + titleHeight + 10,
            width: Config.videoSize.width - 144,
            height: 40
        )
        attributedBadge.draw(in: badgeRect)
    }

    private static func drawRow(_ row: RowLayout, scrollOffset: CGFloat, in context: CGContext) {
        guard row.loopPeriod > 0, !row.periodTile.isEmpty else { return }

        let period = row.loopPeriod
        let normalizedOffset = scrollOffset.truncatingRemainder(dividingBy: period)

        // offset=0 → 첫 컬렉션 이미지가 왼쪽(x=0)부터 보이고, 타일이 화면을 채웁니다.
        var originX = -normalizedOffset

        // 스크롤 중에도 뷰포트 좌측이 비지 않도록 타일을 왼쪽으로 확장합니다.
        while originX > 0 {
            originX -= period
        }

        let drawLimit = Config.videoSize.width + period
        var x = originX

        while x < drawLimit {
            for item in row.periodTile {
                let rect = CGRect(
                    x: x,
                    y: row.centerY - item.size.height / 2,
                    width: item.size.width,
                    height: item.size.height
                )

                if rect.maxX > 0, rect.minX < Config.videoSize.width {
                    drawRoundedImage(item.image, in: rect, context: context)
                }

                x += item.size.width + Config.photoGap
            }
        }
    }

    private static func drawRoundedImage(_ image: UIImage, in rect: CGRect, context: CGContext) {
        context.saveGState()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: Config.cornerRadius)
        path.addClip()
        image.draw(in: rect)
        context.restoreGState()
    }

    // MARK: - Pixel Buffer

    private static func makePixelBuffer(from pool: CVPixelBufferPool) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
        guard status == kCVReturnSuccess else { return nil }
        return pixelBuffer
    }

    private static func makeDrawingContext(for pixelBuffer: CVPixelBuffer) -> CGContext? {
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: Int(Config.videoSize.width),
            height: Int(Config.videoSize.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }

        context.translateBy(x: 0, y: Config.videoSize.height)
        context.scaleBy(x: 1, y: -1)
        return context
    }
}
