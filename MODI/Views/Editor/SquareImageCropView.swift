import SwiftUI

// MARK: - SquareImageCropView

/// 갤러리 사진을 1:1 비율로 확대·이동하며 자르는 화면.
struct SquareImageCropView: View {

    let image: UIImage
    var onConfirm: (UIImage) -> Void
    var onCancel: () -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var cropSide: CGFloat = 0

    private var normalizedImage: UIImage {
        image.normalizedOrientation()
    }

    private var imageSize: CGSize {
        normalizedImage.size
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let side = cropViewportSide(in: geometry.size)

                ZStack {
                    AppColor.Background.grouped
                        .ignoresSafeArea()

                    VStack(spacing: AppSpacing.lg) {
                        Text("사진을 드래그하거나 확대·축소해 원하는 영역을 맞춰보세요")
                            .font(AppFont.footnote)
                            .foregroundStyle(AppColor.Text.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.screenHorizontal)

                        cropCanvas(side: side)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(.top, AppSpacing.md)
                }
                .onAppear {
                    cropSide = side
                    resetTransform(for: side)
                }
                .onChange(of: geometry.size) { _, newSize in
                    let newSide = cropViewportSide(in: newSize)
                    guard newSide > 0, newSide != cropSide else { return }
                    cropSide = newSide
                    resetTransform(for: newSide)
                }
            }
            .navigationTitle("사진 자르기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        onCancel()
                    }
                    .foregroundStyle(AppColor.Text.secondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        confirmCrop()
                    }
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Accent.primary)
                }
            }
            .toolbarBackground(AppColor.Background.primary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Canvas

    private func cropCanvas(side: CGFloat) -> some View {
        ZStack {
            AppColor.Overlay.scrim.opacity(0.95)

            ZStack {
                Image(uiImage: normalizedImage)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(scale)
                    .offset(offset)
            }
            .frame(width: side, height: side)
            .clipped()
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .simultaneousGesture(magnificationGesture)

            squareCropOverlay(side: side)
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }

    private func squareCropOverlay(side: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .strokeBorder(AppColor.Text.onAccent.opacity(0.9), lineWidth: 1.5)
                .frame(width: side, height: side)

            VStack {
                gridLine
                Spacer()
                gridLine
            }
            .frame(width: side, height: side)

            HStack {
                gridLine
                    .rotationEffect(.degrees(90))
                Spacer()
                gridLine
                    .rotationEffect(.degrees(90))
            }
            .frame(width: side, height: side)
        }
        .allowsHitTesting(false)
    }

    private var gridLine: some View {
        Rectangle()
            .fill(AppColor.Text.onAccent.opacity(0.22))
            .frame(height: 0.5)
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let proposed = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                offset = ImageCropUtility.clampedOffset(
                    imageSize: imageSize,
                    viewportSize: CGSize(width: cropSide, height: cropSide),
                    scale: scale,
                    proposedOffset: proposed
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let minimum = ImageCropUtility.minimumScale(
                    imageSize: imageSize,
                    viewportSize: CGSize(width: cropSide, height: cropSide)
                )
                let maximum = ImageCropUtility.maximumScale(
                    imageSize: imageSize,
                    viewportSize: CGSize(width: cropSide, height: cropSide),
                    minimumScale: minimum
                )

                let proposed = lastScale * value
                scale = min(max(proposed, minimum), maximum)
                offset = ImageCropUtility.clampedOffset(
                    imageSize: imageSize,
                    viewportSize: CGSize(width: cropSide, height: cropSide),
                    scale: scale,
                    proposedOffset: offset
                )
            }
            .onEnded { _ in
                lastScale = scale
                lastOffset = offset
            }
    }

    // MARK: - Actions

    private func resetTransform(for side: CGFloat) {
        let viewport = CGSize(width: side, height: side)
        scale = ImageCropUtility.minimumScale(imageSize: imageSize, viewportSize: viewport)
        lastScale = scale
        offset = .zero
        lastOffset = .zero
    }

    private func confirmCrop() {
        let viewport = CGSize(width: cropSide, height: cropSide)
        let cropped = ImageCropUtility.cropSquare(
            image: normalizedImage,
            viewportSize: viewport,
            scale: scale,
            offset: offset
        ) ?? normalizedImage
        onConfirm(cropped)
    }

    private func cropViewportSide(in containerSize: CGSize) -> CGFloat {
        let horizontalPadding = AppSpacing.screenHorizontal * 2
        let maxWidth = max(containerSize.width - horizontalPadding, 1)
        let maxHeight = max(containerSize.height - AppSpacing.massive * 2, 1)
        return min(maxWidth, maxHeight)
    }
}

// MARK: - Preview

#Preview("Light") {
    let size = CGSize(width: 800, height: 1200)
    let renderer = UIGraphicsImageRenderer(size: size)
    let sampleImage = renderer.image { context in
        UIColor.systemTeal.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }

    return SquareImageCropView(
        image: sampleImage,
        onConfirm: { _ in },
        onCancel: {}
    )
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    let size = CGSize(width: 800, height: 1200)
    let renderer = UIGraphicsImageRenderer(size: size)
    let sampleImage = renderer.image { context in
        UIColor.systemTeal.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }

    return SquareImageCropView(
        image: sampleImage,
        onConfirm: { _ in },
        onCancel: {}
    )
    .preferredColorScheme(.dark)
}
