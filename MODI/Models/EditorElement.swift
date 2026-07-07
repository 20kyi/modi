import Foundation
import SwiftUI

// MARK: - EditorElementType

enum EditorElementType: Equatable {
    case sticker(emoji: String)
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
}

// MARK: - EditorSticker

enum EditorSticker {
    static let catalog: [String] = ["☁️", "☀️", "✨", "🌱", "🌸", "🐱", "💙"]
}
