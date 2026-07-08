import Foundation

enum WidgetDataStore {
    private static let snapshotKey = "modi.widget.dailySnapshot"
    private static let todayPhotoFileName = "today-photo.jpg"

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
        do {
            try imageData.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    static func todayPhotoData() -> Data? {
        guard let url = todayPhotoURL,
              FileManager.default.fileExists(atPath: url.path)
        else { return nil }
        return try? Data(contentsOf: url)
    }

    static func removeTodayPhoto() {
        guard let url = todayPhotoURL else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private static var todayPhotoURL: URL? {
        containerURL?.appendingPathComponent(todayPhotoFileName)
    }
}
