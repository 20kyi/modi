import Foundation
import SwiftUI

// MARK: - EditorElementType

enum EditorElementType: Equatable {
    case sticker(emoji: String)
    case text(content: String, color: Color)
}

// MARK: - EditorElement

/// 사진 위에 배치되는 꾸미기 요소.
struct EditorElement: Identifiable, Equatable {
    let id: UUID
    var type: EditorElementType
    var position: CGPoint
    var scale: CGFloat
    var rotation: Angle

    init(
        id: UUID = UUID(),
        type: EditorElementType,
        position: CGPoint = .zero,
        scale: CGFloat = 1.0,
        rotation: Angle = .zero
    ) {
        self.id = id
        self.type = type
        self.position = position
        self.scale = scale
        self.rotation = rotation
    }

    var emoji: String? {
        if case .sticker(let emoji) = type {
            return emoji
        }
        return nil
    }

    var textContent: String? {
        if case .text(let content, _) = type {
            return content
        }
        return nil
    }

    var textColor: Color? {
        if case .text(_, let color) = type {
            return color
        }
        return nil
    }
}

// MARK: - EditorSticker

enum EditorSticker {
    static let catalog: [String] = ["☁️", "☀️", "✨", "🌱", "🌸", "🐱", "💙"]
}

// MARK: - EditorFrameStyle

/// 기록 카드 프레임 스타일.
enum EditorFrameStyle: String, CaseIterable, Identifiable {
    case none
    case classic
    case rounded
    case accent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: "없음"
        case .classic: "클래식"
        case .rounded: "라운드"
        case .accent: "컨셉"
        }
    }

    var iconName: String {
        switch self {
        case .none: "square"
        case .classic: "square.inset.filled"
        case .rounded: "app"
        case .accent: "paintpalette"
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .none: 0
        case .classic: 10
        case .rounded: 14
        case .accent: 8
        }
    }

    var outerPadding: CGFloat {
        switch self {
        case .none: 0
        case .classic: 10
        case .rounded: 14
        case .accent: 10
        }
    }

    func borderColor(themeColor: Color) -> Color {
        switch self {
        case .none: .clear
        case .classic, .rounded: .white
        case .accent: themeColor
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .none: AppRadius.photo
        case .classic: AppRadius.photo
        case .rounded: AppRadius.xl
        case .accent: AppRadius.lg
        }
    }
}

// MARK: - EditorTool

enum EditorTool: String, CaseIterable, Identifiable {
    case sticker
    case text
    case frame

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sticker: "스티커"
        case .text: "텍스트"
        case .frame: "프레임"
        }
    }

    var iconName: String {
        switch self {
        case .sticker: "face.smiling"
        case .text: "textformat"
        case .frame: "square.on.square"
        }
    }
}
