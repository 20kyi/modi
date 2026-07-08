import UIKit

// MARK: - ImageCropUtility

enum ImageCropUtility {

    // MARK: - Square Crop

    /// `aspectRatio(.fill)`로 정사각형 뷰포트에 맞춘 뒤, 확대·이동 값을 반영해 1:1로 자릅니다.
    static func cropSquare(
        image: UIImage,
        viewportSize: CGSize,
        scale: CGFloat = 1,
        offset: CGSize = .zero
    ) -> UIImage? {
        let normalized = image.normalizedOrientation()
        guard
            let cgImage = normalized.cgImage,
            viewportSize.width > 0,
            viewportSize.height > 0
        else { return nil }

        let cropRect = cropRectInImageCoordinates(
            imageSize: normalized.size,
            viewportSize: viewportSize,
            scale: scale,
            offset: offset
        )

        let pixelRect = CGRect(
            x: cropRect.origin.x * normalized.scale,
            y: cropRect.origin.y * normalized.scale,
            width: cropRect.width * normalized.scale,
            height: cropRect.height * normalized.scale
        ).integral

        guard
            let cropped = cgImage.cropping(to: pixelRect),
            pixelRect.width > 0,
            pixelRect.height > 0
        else { return nil }

        return UIImage(cgImage: cropped, scale: normalized.scale, orientation: .up)
    }

    /// 카메라 촬영본을 화면에 보이는 1:1 뷰파인더 영역에 맞게 자릅니다.
    static func cropSquareAspectFill(
        image: UIImage,
        viewportSize: CGSize
    ) -> UIImage? {
        cropSquare(image: image, viewportSize: viewportSize)
    }

    // MARK: - Layout Math

    static func minimumScale(
        imageSize: CGSize,
        viewportSize: CGSize
    ) -> CGFloat {
        guard imageSize.width > 0, imageSize.height > 0 else { return 1 }
        return 1
    }

    static func maximumScale(
        imageSize: CGSize,
        viewportSize: CGSize,
        minimumScale: CGFloat
    ) -> CGFloat {
        max(minimumScale * 5, minimumScale + 0.01)
    }

    static func clampedOffset(
        imageSize: CGSize,
        viewportSize: CGSize,
        scale: CGFloat,
        proposedOffset: CGSize
    ) -> CGSize {
        let metrics = displayMetrics(
            imageSize: imageSize,
            viewportSize: viewportSize,
            scale: scale
        )

        let maxOffsetX = max((metrics.scaledSize.width - viewportSize.width) / 2, 0)
        let maxOffsetY = max((metrics.scaledSize.height - viewportSize.height) / 2, 0)

        return CGSize(
            width: min(max(proposedOffset.width, -maxOffsetX), maxOffsetX),
            height: min(max(proposedOffset.height, -maxOffsetY), maxOffsetY)
        )
    }

    static func cropRectInImageCoordinates(
        imageSize: CGSize,
        viewportSize: CGSize,
        scale: CGFloat,
        offset: CGSize
    ) -> CGRect {
        let metrics = displayMetrics(
            imageSize: imageSize,
            viewportSize: viewportSize,
            scale: scale
        )

        let originX = (viewportSize.width - metrics.scaledSize.width) / 2 + offset.width
        let originY = (viewportSize.height - metrics.scaledSize.height) / 2 + offset.height

        var cropRect = CGRect(
            x: (0 - originX) / metrics.totalScale,
            y: (0 - originY) / metrics.totalScale,
            width: viewportSize.width / metrics.totalScale,
            height: viewportSize.height / metrics.totalScale
        )

        let imageBounds = CGRect(origin: .zero, size: imageSize)
        cropRect = cropRect.intersection(imageBounds)

        if cropRect.width <= 0 || cropRect.height <= 0 {
            return squareCropRect(for: imageSize)
        }

        let side = min(cropRect.width, cropRect.height)
        return CGRect(
            x: cropRect.midX - side / 2,
            y: cropRect.midY - side / 2,
            width: side,
            height: side
        ).intersection(imageBounds)
    }

    // MARK: - Private

    private struct DisplayMetrics {
        let fillScale: CGFloat
        let totalScale: CGFloat
        let scaledSize: CGSize
    }

    private static func displayMetrics(
        imageSize: CGSize,
        viewportSize: CGSize,
        scale: CGFloat
    ) -> DisplayMetrics {
        let fillScale = max(
            viewportSize.width / imageSize.width,
            viewportSize.height / imageSize.height
        )
        let totalScale = fillScale * scale
        let scaledSize = CGSize(
            width: imageSize.width * totalScale,
            height: imageSize.height * totalScale
        )

        return DisplayMetrics(
            fillScale: fillScale,
            totalScale: totalScale,
            scaledSize: scaledSize
        )
    }

    private static func squareCropRect(for imageSize: CGSize) -> CGRect {
        let side = min(imageSize.width, imageSize.height)
        return CGRect(
            x: (imageSize.width - side) / 2,
            y: (imageSize.height - side) / 2,
            width: side,
            height: side
        )
    }
}

// MARK: - UIImage Orientation

extension UIImage {

    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
