import UIKit

// MARK: - PhotoStorage

/// 미션 사진을 Application Support 디렉터리에 로컬 저장.
enum PhotoStorage {

    private static let directoryName = "MissionPhotos"

    static var photosDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent(directoryName, isDirectory: true)

        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory
    }

    @discardableResult
    static func save(image: UIImage, entryID: UUID) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }

        let fileName = "\(entryID.uuidString).jpg"
        let fileURL = photosDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL, options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }

    static func url(for fileName: String) -> URL {
        photosDirectory.appendingPathComponent(fileName)
    }

    static func image(for fileName: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: fileName).path)
    }

    static func delete(fileName: String) {
        let fileURL = url(for: fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
}
