import CoreGraphics
import Foundation
import SwiftUI
import UIKit

// MARK: - Persisted Element Type

enum PersistedElementType: Codable, Equatable {
    case sticker(emoji: String)
    case text(content: String, colorHex: String)
}

// MARK: - Persisted Editor Element

struct PersistedEditorElement: Codable, Equatable, Identifiable {
    let id: UUID
    var elementType: PersistedElementType
    var positionX: Double
    var positionY: Double
    var scale: Double
    var rotationDegrees: Double

    init(from element: EditorElement, canvasSize: CGSize) {
        id = element.id
        positionX = canvasSize.width > 0 ? element.position.x / canvasSize.width : 0
        positionY = canvasSize.height > 0 ? element.position.y / canvasSize.height : 0
        scale = element.scale
        rotationDegrees = element.rotation.degrees

        switch element.type {
        case .sticker(let emoji):
            elementType = .sticker(emoji: emoji)
        case .text(let content, let color):
            elementType = .text(content: content, colorHex: color.persistedHex)
        }
    }

    func toEditorElement(canvasSize: CGSize, usesNormalizedPositions: Bool) -> EditorElement {
        let type: EditorElementType
        switch elementType {
        case .sticker(let emoji):
            type = .sticker(emoji: emoji)
        case .text(let content, let colorHex):
            type = .text(content: content, color: Color(hex: colorHex))
        }

        let position: CGPoint
        if usesNormalizedPositions {
            position = CGPoint(
                x: positionX * canvasSize.width,
                y: positionY * canvasSize.height
            )
        } else {
            position = CGPoint(x: positionX, y: positionY)
        }

        return EditorElement(
            id: id,
            type: type,
            position: position,
            scale: scale,
            rotation: .degrees(rotationDegrees)
        )
    }
}

// MARK: - Editor State

struct EditorState: Codable, Equatable {
    var version: Int
    var elements: [PersistedEditorElement]
    var frameStyle: String
    var canvasWidth: Double
    var canvasHeight: Double

    init(
        version: Int = 2,
        elements: [PersistedEditorElement],
        frameStyle: String,
        canvasWidth: Double,
        canvasHeight: Double
    ) {
        self.version = version
        self.elements = elements
        self.frameStyle = frameStyle
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        elements = try container.decode([PersistedEditorElement].self, forKey: .elements)
        frameStyle = try container.decode(String.self, forKey: .frameStyle)
        canvasWidth = try container.decode(Double.self, forKey: .canvasWidth)
        canvasHeight = try container.decode(Double.self, forKey: .canvasHeight)
    }

    static func from(
        elements: [EditorElement],
        frameStyle: EditorFrameStyle,
        canvasSize: CGSize
    ) -> EditorState {
        EditorState(
            version: 2,
            elements: elements.map { PersistedEditorElement(from: $0, canvasSize: canvasSize) },
            frameStyle: frameStyle.rawValue,
            canvasWidth: canvasSize.width,
            canvasHeight: canvasSize.height
        )
    }

    func elements(for canvasSize: CGSize) -> [EditorElement] {
        if version >= 2 {
            return elements.map { $0.toEditorElement(canvasSize: canvasSize, usesNormalizedPositions: true) }
        }

        let storedSize = CGSize(width: canvasWidth, height: canvasHeight)
        guard storedSize.width > 0, storedSize.height > 0 else {
            return elements.map { $0.toEditorElement(canvasSize: canvasSize, usesNormalizedPositions: false) }
        }

        let scaleX = canvasSize.width / storedSize.width
        let scaleY = canvasSize.height / storedSize.height

        return elements.map { persisted in
            var element = persisted.toEditorElement(canvasSize: canvasSize, usesNormalizedPositions: false)
            element.position = CGPoint(
                x: element.position.x * scaleX,
                y: element.position.y * scaleY
            )
            return element
        }
    }

    var resolvedFrameStyle: EditorFrameStyle {
        EditorFrameStyle(rawValue: frameStyle) ?? .none
    }
}

// MARK: - MODIRecord Helpers

extension MODIRecord {
    var editorState: EditorState? {
        guard let editorStateData else { return nil }
        return try? JSONDecoder().decode(EditorState.self, from: editorStateData)
    }

    /// 편집 화면에 사용할 원본 사진. 저장된 원본이 없으면 표시용 이미지를 사용합니다.
    var editingImage: UIImage? {
        if let originalImageData, let image = UIImage(data: originalImageData) {
            return image
        }
        return UIImage(data: imageData)
    }

    var displayImage: UIImage? {
        UIImage(data: imageData)
    }

    /// 편집기에 추가한 텍스트 요소 내용.
    var userWrittenTexts: [String] {
        guard let editorState else { return [] }

        return editorState.elements.compactMap { element in
            guard case .text(let content, _) = element.elementType else { return nil }
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
    }

    /// 발견 날짜 표시 (예: 2026.07.08)
    var discoveryDateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: discoveryDate)
    }
}

// MARK: - Color Persistence

private extension Color {
    var persistedHex: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(
            format: "%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}
