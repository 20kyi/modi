import SwiftData
import SwiftUI

// MARK: - PhotoEditorView

/// 촬영한 사진 위에 스티커를 배치·편집하는 화면.
struct PhotoEditorView: View {

    let image: UIImage
    let mission: DailyMission
    var onSaved: () -> Void
    var onSaveFailed: ((Error) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(MODIRepository.self) private var repository

    @State private var elements: [EditorElement] = []
    @State private var selectedElementID: UUID?
    @State private var showStickerPicker = false
    @State private var canvasSize: CGSize = .zero

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                editorCanvas
                editorBottomBar
            }
            .appScreenBackground()
            .navigationTitle("꾸미기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveEditedImage()
                    }
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Accent.primary)
                }
            }
            .toolbarBackground(AppColor.Background.primary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showStickerPicker) {
                StickerPickerView { emoji in
                    addSticker(emoji)
                }
            }
        }
    }

    // MARK: Canvas

    private var editorCanvas: some View {
        GeometryReader { geometry in
            let fittedFrame = imageFrame(in: geometry.size)

            ZStack {
                AppColor.Background.grouped

                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: fittedFrame.width, height: fittedFrame.height)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
                        .appShadow(.medium)

                    ForEach($elements) { $element in
                        EditorElementOverlay(
                            element: $element,
                            isSelected: selectedElementID == element.id,
                            onSelect: { selectedElementID = element.id }
                        )
                    }
                }
                .frame(width: fittedFrame.width, height: fittedFrame.height)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .onTapGesture {
                    selectedElementID = nil
                }
                .onAppear {
                    canvasSize = fittedFrame.size
                }
                .onChange(of: geometry.size) { _, newSize in
                    canvasSize = imageFrame(in: newSize).size
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Bottom Bar

    private var editorBottomBar: some View {
        VStack(spacing: AppSpacing.md) {
            Button {
                showStickerPicker = true
            } label: {
                Label("스티커 추가", systemImage: "face.smiling")
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Text.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        AppColor.Background.secondary,
                        in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    )
            }
            .buttonStyle(.plain)

            Button {
                saveEditedImage()
            } label: {
                Text("저장하기")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.lg)
        .background(AppColor.Background.primary)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColor.Border.subtle)
                .frame(height: 0.5)
        }
    }

    // MARK: Actions

    private func addSticker(_ emoji: String) {
        let center = CGPoint(
            x: canvasSize.width / 2,
            y: canvasSize.height / 2
        )

        let element = EditorElement(
            type: .sticker(emoji: emoji),
            position: center,
            scale: 1.0
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            elements.append(element)
            selectedElementID = element.id
        }
    }

    private func saveEditedImage() {
        let content = EditorRenderCanvas(image: image, elements: elements, canvasSize: canvasSize)
        let renderer = ImageRenderer(content: content)
        renderer.scale = UIScreen.main.scale

        let editedImage = renderer.uiImage ?? image

        do {
            try repository.saveRecord(image: editedImage, mission: mission)
            onSaved()
            dismiss()
        } catch {
            onSaveFailed?(error)
        }
    }

    private func imageFrame(in containerSize: CGSize) -> CGRect {
        guard image.size.width > 0, image.size.height > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }

        let imageAspect = image.size.width / image.size.height
        let containerAspect = containerSize.width / containerSize.height
        let horizontalPadding = AppSpacing.screenHorizontal * 2

        let maxWidth = max(containerSize.width - horizontalPadding, 1)
        let maxHeight = max(containerSize.height - AppSpacing.xxxl, 1)

        let width: CGFloat
        let height: CGFloat

        if imageAspect > containerAspect {
            width = maxWidth
            height = width / imageAspect
        } else {
            height = min(maxHeight, containerSize.height * 0.85)
            width = height * imageAspect
        }

        let origin = CGPoint(
            x: (containerSize.width - width) / 2,
            y: (containerSize.height - height) / 2
        )

        return CGRect(origin: origin, size: CGSize(width: width, height: height))
    }
}

// MARK: - Editor Element Overlay

private struct EditorElementOverlay: View {

    @Binding var element: EditorElement
    let isSelected: Bool
    var onSelect: () -> Void

    @State private var dragOffset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var rotateBy: Angle = .zero

    private let baseStickerSize: CGFloat = 48

    var body: some View {
        Group {
            if let emoji = element.emoji {
                Text(emoji)
                    .font(.system(size: baseStickerSize * element.scale * magnifyBy))
                    .rotationEffect(element.rotation + rotateBy)
            }
        }
        .position(
            x: element.position.x + dragOffset.width,
            y: element.position.y + dragOffset.height
        )
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .strokeBorder(AppColor.Accent.primary, lineWidth: 1.5)
                    .frame(
                        width: baseStickerSize * element.scale * magnifyBy + AppSpacing.lg,
                        height: baseStickerSize * element.scale * magnifyBy + AppSpacing.lg
                    )
                    .position(
                        x: element.position.x + dragOffset.width,
                        y: element.position.y + dragOffset.height
                    )
                    .allowsHitTesting(false)
            }
        }
        .gesture(dragGesture)
        .simultaneousGesture(magnificationGesture)
        .simultaneousGesture(rotationGesture)
        .onTapGesture {
            onSelect()
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                onSelect()
                dragOffset = value.translation
            }
            .onEnded { value in
                element.position.x += value.translation.width
                element.position.y += value.translation.height
                dragOffset = .zero
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .updating($magnifyBy) { value, state, _ in
                state = value
            }
            .onEnded { value in
                let newScale = element.scale * value
                element.scale = min(max(newScale, 0.4), 3.0)
            }
    }

    private var rotationGesture: some Gesture {
        RotationGesture()
            .updating($rotateBy) { value, state, _ in
                state = value
            }
            .onEnded { value in
                element.rotation += value
            }
    }
}

// MARK: - Render Canvas

private struct EditorRenderCanvas: View {
    let image: UIImage
    let elements: [EditorElement]
    let canvasSize: CGSize

    private let baseStickerSize: CGFloat = 48

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: canvasSize.width, height: canvasSize.height)

            ForEach(elements) { element in
                if let emoji = element.emoji {
                    Text(emoji)
                        .font(.system(size: baseStickerSize * element.scale))
                        .rotationEffect(element.rotation)
                        .position(element.position)
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }
}

// MARK: - Preview

#Preview {
    let (container, repository) = MODIPreviewData.makeRepository()
    return PhotoEditorView(
        image: UIImage(systemName: "photo")!
            .withTintColor(.gray, renderingMode: .alwaysOriginal),
        mission: .mock
    ) {}
    .modelContainer(container)
    .environment(repository)
}
