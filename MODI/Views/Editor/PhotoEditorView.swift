import SwiftData
import SwiftUI

// MARK: - PhotoEditorView

/// 촬영·앨범 사진을 MODI 기록 카드로 꾸미는 편집 화면.
struct PhotoEditorView: View {

    let image: UIImage
    var concept: Concept?
    var collection: MODICollection?
    var existingRecord: MODIRecord?
    var onSaved: () -> Void
    var onSaveFailed: ((Error) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(RecordRepository.self) private var repository
    @Environment(CollectionRepository.self) private var collectionRepository

    @State private var elements: [EditorElement] = []
    @State private var selectedElementID: UUID?
    @State private var activeTool: EditorTool = .sticker
    @State private var selectedFrame: EditorFrameStyle = .none
    @State private var canvasSize: CGSize = .zero
    @State private var showTextInput = false
    @State private var draftText = ""
    @State private var savedEditorState: EditorState?
    @State private var shouldSyncFromSavedState = true
    @State private var showRevertAlert = false

    private var originalPhoto: UIImage {
        if let existingRecord,
           let data = existingRecord.originalImageData,
           let original = UIImage(data: data) {
            return original
        }
        return image
    }

    private var canRevertToOriginal: Bool {
        !elements.isEmpty || selectedFrame != .none || existingRecord?.editorState != nil
    }

    private var resolvedConcept: Concept? {
        if let concept { return concept }
        if let existingRecord {
            return Concept.concept(for: existingRecord.conceptId)
        }
        return nil
    }

    private var themeColor: Color {
        if let resolvedConcept {
            return Color(hex: resolvedConcept.themeColorHex)
        }
        return AppColor.Accent.soft
    }

    private var frameMetadata: EditorFrameMetadata {
        EditorFrameMetadata(
            showDate: true,
            showConceptName: resolvedConcept != nil,
            date: existingRecord?.createdAt ?? .now,
            conceptTitle: resolvedConcept?.title
        )
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
            .alert("원본으로 되돌릴까요?", isPresented: $showRevertAlert) {
                Button("되돌리기", role: .destructive) {
                    revertToOriginal()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("추가한 스티커, 텍스트, 프레임이 모두 제거돼요.")
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
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    selectedElementID = nil
                }
                .onAppear {
                    prepareEditorState()
                    updateCanvasSize(fittedFrame.size)
                }
                .onChange(of: geometry.size) { _, newSize in
                    updateCanvasSize(imageFrame(in: newSize).size)
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
                    onSelect: {
                        markEditorStateAsModified()
                        guard selectedElementID != element.id else { return }
                        selectedElementID = element.id
                    },
                    onDelete: { deleteElement(id: element.id) },
                    onInteraction: markEditorStateAsModified
                )
            }
        }
        .appShadow(.medium)
    }

    private func deleteElement(id: UUID) {
        markEditorStateAsModified()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            elements.removeAll { $0.id == id }
            if selectedElementID == id {
                selectedElementID = nil
            }
        }
    }

    private func framedPhoto(size: CGSize) -> some View {
        let photoSize = photoContentSize(for: size)

        return ZStack {
            if selectedFrame != .none {
                RoundedRectangle(cornerRadius: selectedFrame.cornerRadius, style: .continuous)
                    .fill(selectedFrame.borderColor(themeColor: themeColor))
                    .frame(width: size.width, height: size.height)
            }

            Image(uiImage: originalPhoto)
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

    // MARK: Toolbar

    private var editorToolbar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppColor.Border.subtle)
                .frame(height: 0.5)

            if canRevertToOriginal {
                Button {
                    showRevertAlert = true
                } label: {
                    Label("원본으로 되돌리기", systemImage: "arrow.uturn.backward")
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }

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
            StickerPickerView(onSelect: addSticker)
        case .text:
            TextPickerView(
                onSelect: addText,
                onRequestCustomInput: { showTextInput = true }
            )
        case .frame:
            FramePickerView(
                selectedFrame: $selectedFrame,
                metadata: frameMetadata,
                themeColor: themeColor
            )
            .onChange(of: selectedFrame) { _, _ in
                markEditorStateAsModified()
            }
        }
    }

    // MARK: Actions

    private func addSticker(_ emoji: String) {
        markEditorStateAsModified()
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
        markEditorStateAsModified()
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

    private func prepareEditorState() {
        guard savedEditorState == nil,
              let existingRecord,
              let state = existingRecord.editorState else { return }

        savedEditorState = state
        shouldSyncFromSavedState = true
        selectedFrame = state.resolvedFrameStyle
    }

    private func markEditorStateAsModified() {
        shouldSyncFromSavedState = false
    }

    private func updateCanvasSize(_ newSize: CGSize) {
        guard newSize.width > 0, newSize.height > 0 else { return }

        let previousSize = canvasSize

        if shouldSyncFromSavedState, let savedEditorState {
            elements = savedEditorState.elements(for: newSize)
            selectedFrame = savedEditorState.resolvedFrameStyle
        } else if previousSize.width > 0,
                  previousSize.height > 0,
                  previousSize != newSize,
                  !elements.isEmpty {
            let scaleX = newSize.width / previousSize.width
            let scaleY = newSize.height / previousSize.height
            elements = elements.map { element in
                var updated = element
                updated.position = CGPoint(
                    x: element.position.x * scaleX,
                    y: element.position.y * scaleY
                )
                return updated
            }
        }

        canvasSize = newSize
    }

    private func revertToOriginal() {
        markEditorStateAsModified()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            elements.removeAll()
            selectedFrame = .none
            selectedElementID = nil
        }
    }

    private func saveEditedImage() {
        guard let concept = resolvedConcept else {
            onSaveFailed?(RecordRepositoryError.missingConcept)
            return
        }

        let wasEdited = !elements.isEmpty || selectedFrame != .none
        let renderedImage: UIImage

        if wasEdited {
            let content = EditorRenderCanvas(
                image: originalPhoto,
                elements: elements,
                canvasSize: canvasSize,
                frameStyle: selectedFrame,
                themeColor: themeColor
            )
            let renderer = ImageRenderer(content: content)
            renderer.scale = UIScreen.main.scale
            renderedImage = renderer.uiImage ?? originalPhoto
        } else {
            renderedImage = originalPhoto
        }

        let editorState = wasEdited
            ? EditorState.from(elements: elements, frameStyle: selectedFrame, canvasSize: canvasSize)
            : nil

        do {
            let linkedCollection = collection ?? collectionRepository.ensureCollection(for: concept)

            if let existingRecord {
                try repository.updateRecord(
                    existingRecord,
                    image: renderedImage,
                    originalImage: originalPhoto,
                    editorState: editorState,
                    isEdited: wasEdited
                )
                collectionRepository.linkRecord(existingRecord, to: linkedCollection)
            } else {
                _ = try repository.saveRecord(
                    image: renderedImage,
                    originalImage: originalPhoto,
                    concept: concept,
                    collection: linkedCollection,
                    editorState: editorState,
                    isEdited: wasEdited
                )
            }
            collectionRepository.reload()
            onSaved()
            dismiss()
        } catch {
            onSaveFailed?(error)
        }
    }

    private func imageFrame(in containerSize: CGSize) -> CGRect {
        guard originalPhoto.size.width > 0, originalPhoto.size.height > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }

        let imageAspect = originalPhoto.size.width / originalPhoto.size.height
        let horizontalPadding = AppSpacing.screenHorizontal * 2

        let maxWidth = max(containerSize.width - horizontalPadding, 1)
        let maxHeight = max(containerSize.height - AppSpacing.xl, 1)

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
    var onDelete: () -> Void
    var onInteraction: () -> Void

    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var rotateBy: Angle = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var didBeginDrag = false

    private let baseStickerSize: CGFloat = 48
    private let baseTextSize: CGFloat = 17

    var body: some View {
        elementContent
            .overlay {
                if isSelected {
                    selectionBorder
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    deleteButton
                        .offset(x: 8, y: -8)
                }
            }
            .animation(.none, value: isSelected)
            .position(
                x: element.position.x + dragOffset.width,
                y: element.position.y + dragOffset.height
            )
            .gesture(dragGesture)
            .simultaneousGesture(magnificationGesture)
            .simultaneousGesture(rotationGesture)
            .onTapGesture {
                onSelect()
            }
    }

    private var deleteButton: some View {
        Button {
            onDelete()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
                .background(Color.black.opacity(0.6), in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.85), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("삭제")
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
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if !didBeginDrag {
                    didBeginDrag = true
                    if !isSelected {
                        onSelect()
                    }
                }
                dragOffset = value.translation
            }
            .onEnded { value in
                element.position.x += value.translation.width
                element.position.y += value.translation.height
                dragOffset = .zero
                didBeginDrag = false
                onInteraction()
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
                onInteraction()
            }
    }

    private var rotationGesture: some Gesture {
        RotationGesture()
            .updating($rotateBy) { value, state, _ in
                state = value
            }
            .onEnded { value in
                element.rotation += value
                onInteraction()
            }
    }
}

// MARK: - Render Canvas

private struct EditorRenderCanvas: View {
    let image: UIImage
    let elements: [EditorElement]
    let canvasSize: CGSize
    let frameStyle: EditorFrameStyle
    let themeColor: Color

    private let baseStickerSize: CGFloat = 48
    private let baseTextSize: CGFloat = 17

    var body: some View {
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
}

// MARK: - Preview

#Preview("With Concept") {
    let (container, repository) = RecordPreviewData.makeRepository()
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
    .environment(CollectionRepository(modelContext: container.mainContext))
}

#Preview("Without Concept") {
    let (container, repository) = RecordPreviewData.makeRepository()
    let size = CGSize(width: 300, height: 400)
    let renderer = UIGraphicsImageRenderer(size: size)
    let sampleImage = renderer.image { context in
        UIColor.systemPink.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }

    return PhotoEditorView(image: sampleImage) {}
        .modelContainer(container)
        .environment(repository)
        .environment(CollectionRepository(modelContext: container.mainContext))
}
