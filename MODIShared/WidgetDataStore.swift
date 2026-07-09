import Foundation
import UIKit

enum WidgetDataStore {
    private static let snapshotKey = "modi.widget.dailySnapshot"
    private static let todayPhotoFileName = "today-photo.jpg"
    private static let widgetPhotoMaxArea: CGFloat = 1_000_000
    private static let widgetPhotoCompressionQuality: CGFloat = 0.82

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConstants.identifier)
    }

    static var containerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppGroupConstants.identifier
        )
    }

    static func save(_ snapshot: WidgetDailySnapshot) {
        guard let defaults = sharedDefaults,
              let data = try? JSONEncoder().encode(snapshot)
        else { return }
        defaults.set(data, forKey: snapshotKey)
    }

    static func load() -> WidgetDailySnapshot? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetDailySnapshot.self, from: data)
        else { return nil }
        return snapshot
    }

    static func loadOrPlaceholder() -> WidgetDailySnapshot {
        guard let snapshot = load() else { return .placeholder }
        let todayKey = WidgetDayKey.today
        guard snapshot.dayKey == todayKey else { return .placeholder }
        return snapshot
    }

    @discardableResult
    static func saveTodayPhoto(_ imageData: Data) -> Bool {
        guard let url = todayPhotoURL else { return false }
        let storableData = makeWidgetSizedPhotoData(from: imageData) ?? imageData
        do {
            try storableData.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    static func todayPhotoData() -> Data? {
        guard let url = todayPhotoURL,
              FileManager.default.fileExists(atPath: url.path)
        else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        if let image = UIImage(data: data) {
            let area = image.size.width * image.size.height
            if area > widgetPhotoMaxArea,
               let optimizedData = makeWidgetSizedPhotoData(from: data) {
                try? optimizedData.write(to: url, options: .atomic)
                return optimizedData
            }
        }
        return data
    }

    static func removeTodayPhoto() {
        guard let url = todayPhotoURL else { return }
        try? FileManager.default.removeItem(at: url)
    }

    static func clearAll() {
        sharedDefaults?.removeObject(forKey: snapshotKey)
        removeTodayPhoto()
    }

    private static var todayPhotoURL: URL? {
        containerURL?.appendingPathComponent(todayPhotoFileName)
    }

    private static func makeWidgetSizedPhotoData(from imageData: Data) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }

        let originalSize = image.size
        let originalArea = max(originalSize.width * originalSize.height, 1)
        guard originalArea > widgetPhotoMaxArea else {
            return image.jpegData(compressionQuality: widgetPhotoCompressionQuality)
        }

        let scaleRatio = sqrt(widgetPhotoMaxArea / originalArea)
        let targetSize = CGSize(
            width: max(1, floor(originalSize.width * scaleRatio)),
            height: max(1, floor(originalSize.height * scaleRatio))
        )

        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = 1
        rendererFormat.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: rendererFormat)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resizedImage.jpegData(compressionQuality: widgetPhotoCompressionQuality)
    }
}
