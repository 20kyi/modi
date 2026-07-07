import SwiftData
import SwiftUI

// MARK: - PhotoEditorView

/// 촬영한 사진을 컨셉 기록 카드로 꾸미는 편집 화면.
struct PhotoEditorView: View {

    let image: UIImage
    let concept: Concept
    var onSaved: () -> Void
    var onSaveFailed: ((Error) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(MODIRepository.self) private var repository

    @State private var elements: [EditorElement] = []
    @State private var selectedElementID: UUID?
    @State private var activeTool: EditorTool = .sticker
    @State private var selectedFrame: EditorFrameStyle = .none
    @State private var canvasSize: CGSize = .zero
    @State private var showTextInput = false
    @State private var draftText = ""

    private var themeColor: Color {
        Color(hex: concept.themeColorHex)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                editorCanvas
                editorToolbar
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
                    .accessibilityLabel("뒤로가기")
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
            .sheet(isPresented: $showTextInput) {
                TextInputSheet(text: $draftText) { content in
                    addText(content)
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

                VStack(spacing: AppSpacing.md) {
                    recordCard(in: fittedFrame.size)
                        .frame(width: fittedFrame.width, height: fittedFrame.height)

                    conceptInfoBar
                        .frame(width: fittedFrame.width)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private func recordCard(in size: CGSize) -> some View {
        ZStack {
            framedPhoto(size: size)

            ForEach($elements) { $element in
                EditorElementOverlay(
                    element: $element,
                    isSelected: selectedElementID == element.id,
                    onSelect: { selectedElementID = element.id }
                )
            }
        }
        .appShadow(.medium)
    }

    private func framedPhoto(size: CGSize) -> some View {
        let photoSize = photoContentSize(for: size)

        return ZStack {
            if selectedFrame != .none {
                RoundedRectangle(cornerRadius: selectedFrame.cornerRadius, style: .continuous)
                    .fill(selectedFrame.borderColor(themeColor: themeColor))
                    .frame(width: size.width, height: size.height)
            }

            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: photoSize.width, height: photoSize.height)
                .clipShape(RoundedRectangle(cornerRadius: innerPhotoRadius, style: .continuous))
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: selectedFrame.cornerRadius, style: .continuous))
    }

    private var innerPhotoRadius: CGFloat {
        switch selectedFrame {
        case .none: AppRadius.photo
        case .classic: AppRadius.sm
        case .rounded: AppRadius.lg
        case .accent: AppRadius.md
        }
    }

    private func photoContentSize(for canvasSize: CGSize) -> CGSize {
        let inset = selectedFrame.outerPadding * 2
        return CGSize(
            width: max(canvasSize.width - inset, 1),
            height: max(canvasSize.height - inset, 1)
        )
    }

    private var conceptInfoBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(concept.emoji)
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(concept.title)
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1)

                Text(concept.description)
                    .font(AppFont.caption1)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            themeColor.opacity(0.35),
            in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(themeColor.opacity(0.5), lineWidth: 1)
        }
    }

    // MARK: Toolbar

    private var editorToolbar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppColor.Border.subtle)
                .frame(height: 0.5)

            HStack(spacing: AppSpacing.sm) {
                ForEach(EditorTool.allCases) { tool in
                    toolButton(for: tool)
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.md)

            toolPanel
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.lg)
        }
        .background(AppColor.Background.primary)
    }

    private func toolButton(for tool: EditorTool) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                activeTool = tool
            }
        } label: {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: tool.iconName)
                    .font(.system(size: 18, weight: .semibold))

                Text(tool.title)
                    .font(AppFont.caption1)
            }
            .foregroundStyle(activeTool == tool ? AppColor.Accent.primary : AppColor.Text.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(
                activeTool == tool ? AppColor.Accent.soft : AppColor.Background.secondary,
                in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tool.title)
    }

    @ViewBuilder
    private var toolPanel: some View {
        switch activeTool {
        case .sticker:
            stickerPanel
        case .text:
            textPanel
        case .frame:
            framePanel
        }
    }

    private var stickerPanel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(EditorSticker.catalog, id: \.self) { sticker in
                    Button {
                        addSticker(sticker)
                    } label: {
                        Text(sticker)
                            .font(.system(size: 32))
                            .frame(width: 56, height: 56)
                            .background(
                                AppColor.Background.secondary,
                                in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                    .strokeBorder(AppColor.Border.default, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var textPanel: some View {
        VStack(spacing: AppSpacing.sm) {
            Button {
                showTextInput = true
            } label: {
                Label("텍스트 추가", systemImage: "plus")
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

            Text("추가한 텍스트는 사진 위에서 드래그할 수 있어요")
                .font(AppFont.footnote)
                .foregroundStyle(AppColor.Text.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var framePanel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(EditorFrameStyle.allCases) { frame in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            selectedFrame = frame
                        }
                    } label: {
                        VStack(spacing: AppSpacing.xs) {
                            ZStack {
                                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                    .fill(AppColor.Background.tertiary)
                                    .frame(width: 52, height: 52)

                                framePreview(for: frame)
                            }
                            .overlay {
                                if selectedFrame == frame {
                                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                        .strokeBorder(AppColor.Accent.primary, lineWidth: 2)
                                }
                            }

                            Text(frame.displayName)
                                .font(AppFont.caption2)
                                .foregroundStyle(
                                    selectedFrame == frame
                                        ? AppColor.Accent.primary
                                        : AppColor.Text.secondary
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(width: 64)
                }
            }
        }
    }

    @ViewBuilder
    private func framePreview(for frame: EditorFrameStyle) -> some View {
        RoundedRectangle(cornerRadius: frame == .rounded ? 6 : 3, style: .continuous)
            .fill(AppColor.Surface.muted)
            .frame(width: 36, height: 36)
            .padding(frame == .none ? 0 : 4)
            .background {
                if frame != .none {
                    RoundedRectangle(cornerRadius: frame == .rounded ? 8 : 5, style: .continuous)
                        .fill(frame.borderColor(themeColor: themeColor))
                }
            }
    }

    // MARK: Actions

    private func addSticker(_ emoji: String) {
        let center = defaultElementPosition()

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

    private func addText(_ content: String) {
        let center = defaultElementPosition()

        let element = EditorElement(
            type: .text(content: content, color: .white),
            position: center,
            scale: 1.0
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            elements.append(element)
            selectedElementID = element.id
            activeTool = .text
        }
    }

    private func defaultElementPosition() -> CGPoint {
        CGPoint(
            x: canvasSize.width / 2,
            y: canvasSize.height * 0.42
        )
    }

    private func saveEditedImage() {
        let mission = DailyMission(from: concept)
        let content = EditorRenderCanvas(
            image: image,
            concept: concept,
            elements: elements,
            canvasSize: canvasSize,
            frameStyle: selectedFrame
        )
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
        let horizontalPadding = AppSpacing.screenHorizontal * 2
        let conceptBarHeight: CGFloat = 56 + AppSpacing.md

        let maxWidth = max(containerSize.width - horizontalPadding, 1)
        let maxHeight = max(containerSize.height - conceptBarHeight - AppSpacing.xl, 1)

        let width: CGFloat
        let height: CGFloat

        if imageAspect > maxWidth / maxHeight {
            width = maxWidth
            height = width / imageAspect
        } else {
            height = maxHeight
            width = height * imageAspect
        }

        let origin = CGPoint(
            x: (containerSize.width - width) / 2,
            y: (containerSize.height - height - conceptBarHeight) / 2
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
    private let baseTextSize: CGFloat = 17

    var body: some View {
        elementContent
            .position(
                x: element.position.x + dragOffset.width,
                y: element.position.y + dragOffset.height
            )
            .overlay {
                if isSelected {
                    selectionBorder
                }
            }
            .gesture(dragGesture)
            .simultaneousGesture(magnificationGesture)
            .simultaneousGesture(rotationGesture)
            .onTapGesture {
                onSelect()
            }
    }

    @ViewBuilder
    private var elementContent: some View {
        if let emoji = element.emoji {
            Text(emoji)
                .font(.system(size: baseStickerSize * element.scale * magnifyBy))
                .rotationEffect(element.rotation + rotateBy)
        } else if let content = element.textContent, let color = element.textColor {
            Text(content)
                .font(.system(size: baseTextSize * element.scale * magnifyBy, weight: .semibold))
                .foregroundStyle(color)
                .shadow(color: .black.opacity(0.45), radius: 3, y: 1)
                .rotationEffect(element.rotation + rotateBy)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
        }
    }

    private var selectionBorder: some View {
        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
            .strokeBorder(AppColor.Accent.primary, lineWidth: 1.5)
            .frame(
                width: selectionSize.width + AppSpacing.lg,
                height: selectionSize.height + AppSpacing.lg
            )
            .position(
                x: element.position.x + dragOffset.width,
                y: element.position.y + dragOffset.height
            )
            .allowsHitTesting(false)
    }

    private var selectionSize: CGSize {
        if element.emoji != nil {
            let side = baseStickerSize * element.scale * magnifyBy
            return CGSize(width: side, height: side)
        }
        return CGSize(width: 120, height: 36)
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
    let concept: Concept
    let elements: [EditorElement]
    let canvasSize: CGSize
    let frameStyle: EditorFrameStyle

    private let baseStickerSize: CGFloat = 48
    private let baseTextSize: CGFloat = 17

    private var themeColor: Color {
        Color(hex: concept.themeColorHex)
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                if frameStyle != .none {
                    RoundedRectangle(cornerRadius: frameStyle.cornerRadius, style: .continuous)
                        .fill(frameStyle.borderColor(themeColor: themeColor))
                        .frame(width: canvasSize.width, height: canvasSize.height)
                }

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: photoContentSize.width,
                        height: photoContentSize.height
                    )
                    .clipShape(RoundedRectangle(cornerRadius: innerPhotoRadius, style: .continuous))

                ForEach(elements) { element in
                    if let emoji = element.emoji {
                        Text(emoji)
                            .font(.system(size: baseStickerSize * element.scale))
                            .rotationEffect(element.rotation)
                            .position(element.position)
                    } else if let content = element.textContent, let color = element.textColor {
                        Text(content)
                            .font(.system(size: baseTextSize * element.scale, weight: .semibold))
                            .foregroundStyle(color)
                            .shadow(color: .black.opacity(0.45), radius: 3, y: 1)
                            .rotationEffect(element.rotation)
                            .position(element.position)
                    }
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .clipShape(RoundedRectangle(cornerRadius: frameStyle.cornerRadius, style: .continuous))

            conceptInfoBar
                .frame(width: canvasSize.width)
        }
        .frame(width: canvasSize.width)
    }

    private var photoContentSize: CGSize {
        let inset = frameStyle.outerPadding * 2
        return CGSize(
            width: max(canvasSize.width - inset, 1),
            height: max(canvasSize.height - inset, 1)
        )
    }

    private var innerPhotoRadius: CGFloat {
        switch frameStyle {
        case .none: AppRadius.photo
        case .classic: AppRadius.sm
        case .rounded: AppRadius.lg
        case .accent: AppRadius.md
        }
    }

    private var conceptInfoBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(concept.emoji)
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(concept.title)
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1)

                Text(concept.description)
                    .font(AppFont.caption1)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            themeColor.opacity(0.35),
            in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(themeColor.opacity(0.5), lineWidth: 1)
        }
    }
}

// MARK: - Preview

#Preview {
    let (container, repository) = MODIPreviewData.makeRepository()
    let size = CGSize(width: 300, height: 400)
    let renderer = UIGraphicsImageRenderer(size: size)
    let sampleImage = renderer.image { context in
        UIColor.systemTeal.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }

    return PhotoEditorView(
        image: sampleImage,
        concept: .mock
    ) {}
    .modelContainer(container)
    .environment(repository)
}
