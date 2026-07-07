import SwiftData
import SwiftUI

// MARK: - PhotoEditorView

/// 촬영·앨범 사진을 MODI 기록 카드로 꾸미는 편집 화면.
struct PhotoEditorView: View {

    let image: UIImage
    var concept: Concept?
    var existingRecord: MODIRecord?
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

    private var resolvedConcept: Concept? {
        if let concept { return concept }
        if let existingRecord {
            return Concept.concept(for: existingRecord.missionId)
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

                    if let resolvedConcept {
                        conceptInfoBar(for: resolvedConcept)
                            .frame(width: fittedFrame.width)
                    } else if selectedFrame != .none {
                        frameDateBar
                            .frame(width: fittedFrame.width)
                    }
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
                    onSelect: {
                        guard selectedElementID != element.id else { return }
                        selectedElementID = element.id
                    },
                    onDelete: { deleteElement(id: element.id) }
                )
            }
        }
        .appShadow(.medium)
    }

    private func deleteElement(id: UUID) {
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

    private func conceptInfoBar(for concept: Concept) -> some View {
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

            Text(frameMetadata.formattedDate)
                .font(AppFont.caption2)
                .foregroundStyle(AppColor.Text.tertiary)
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

    private var frameDateBar: some View {
        HStack {
            Label(frameMetadata.formattedDate, systemImage: "calendar")
                .font(AppFont.caption1)
                .foregroundStyle(AppColor.Text.secondary)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            AppColor.Background.secondary,
            in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        )
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
        let mission = saveMission
        let content = EditorRenderCanvas(
            image: image,
            concept: resolvedConcept,
            frameMetadata: frameMetadata,
            elements: elements,
            canvasSize: canvasSize,
            frameStyle: selectedFrame,
            themeColor: themeColor
        )
        let renderer = ImageRenderer(content: content)
        renderer.scale = UIScreen.main.scale

        let editedImage = renderer.uiImage ?? image

        do {
            if let existingRecord {
                try repository.updateRecord(existingRecord, image: editedImage)
            } else {
                try repository.saveRecord(image: editedImage, mission: mission)
            }
            onSaved()
            dismiss()
        } catch {
            onSaveFailed?(error)
        }
    }

    private var saveMission: DailyMission {
        if let resolvedConcept {
            return DailyMission(from: resolvedConcept)
        }
        if let existingRecord {
            return DailyMission(
                title: existingRecord.missionTitle,
                emoji: existingRecord.missionEmoji,
                description: "",
                category: .custom,
                themeColorHex: "E8ECF0",
                collectionID: existingRecord.missionId
            )
        }
        return .mock
    }

    private func imageFrame(in containerSize: CGSize) -> CGRect {
        guard image.size.width > 0, image.size.height > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }

        let imageAspect = image.size.width / image.size.height
        let horizontalPadding = AppSpacing.screenHorizontal * 2
        let conceptBarHeight: CGFloat = resolvedConcept != nil || selectedFrame != .none
            ? 56 + AppSpacing.md
            : 0

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
    var onDelete: () -> Void

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
    let concept: Concept?
    let frameMetadata: EditorFrameMetadata
    let elements: [EditorElement]
    let canvasSize: CGSize
    let frameStyle: EditorFrameStyle
    let themeColor: Color

    private let baseStickerSize: CGFloat = 48
    private let baseTextSize: CGFloat = 17

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

            if let concept {
                conceptInfoBar(for: concept)
                    .frame(width: canvasSize.width)
            } else if frameStyle != .none {
                frameDateBar
                    .frame(width: canvasSize.width)
            }
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

    private func conceptInfoBar(for concept: Concept) -> some View {
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

            Text(frameMetadata.formattedDate)
                .font(AppFont.caption2)
                .foregroundStyle(AppColor.Text.tertiary)
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

    private var frameDateBar: some View {
        HStack {
            Label(frameMetadata.formattedDate, systemImage: "calendar")
                .font(AppFont.caption1)
                .foregroundStyle(AppColor.Text.secondary)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            AppColor.Background.secondary,
            in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        )
    }
}

// MARK: - Preview

#Preview("With Concept") {
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

#Preview("Without Concept") {
    let (container, repository) = MODIPreviewData.makeRepository()
    let size = CGSize(width: 300, height: 400)
    let renderer = UIGraphicsImageRenderer(size: size)
    let sampleImage = renderer.image { context in
        UIColor.systemPink.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }

    return PhotoEditorView(image: sampleImage) {}
        .modelContainer(container)
        .environment(repository)
}
