import Foundation
import Observation
import SwiftData
import UIKit

// MARK: - MODIRepositoryError

enum MODIRepositoryError: LocalizedError {
    case imageEncodingFailed

    var errorDescription: String? {
        switch self {
        case .imageEncodingFailed:
            "사진 데이터를 변환하지 못했어요."
        }
    }
}

// MARK: - MODIRepository

@MainActor
@Observable
final class MODIRepository {

    private let modelContext: ModelContext
    private(set) var records: [MODIRecord] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        reload()
    }

    // MARK: - Save

    @discardableResult
    func saveRecord(image: UIImage, mission: DailyMission) throws -> MODIRecord {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw MODIRepositoryError.imageEncodingFailed
        }

        let record = MODIRecord(
            imageData: imageData,
            missionId: mission.collectionID,
            missionTitle: mission.title,
            missionEmoji: mission.emoji
        )

        modelContext.insert(record)
        try modelContext.save()
        reload()
        return record
    }

    func updateRecord(_ record: MODIRecord, image: UIImage) throws {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw MODIRepositoryError.imageEncodingFailed
        }

        record.imageData = imageData
        try modelContext.save()
        reload()
    }

    // MARK: - Fetch

    func reload() {
        let descriptor = FetchDescriptor<MODIRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        records = (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchAllRecords() -> [MODIRecord] {
        records
    }

    func fetchRecords(missionId: UUID) -> [MODIRecord] {
        records.filter { $0.missionId == missionId }
    }

    func photoCount(for missionId: UUID) -> Int {
        fetchRecords(missionId: missionId).count
    }

    func hasRecord(on date: Date, missionId: UUID) -> Bool {
        let dayKey = DailyMission.dayKey(for: date)
        return records.contains {
            $0.missionId == missionId &&
            DailyMission.dayKey(for: $0.createdAt) == dayKey
        }
    }

    func record(on date: Date, missionId: UUID) -> MODIRecord? {
        let dayKey = DailyMission.dayKey(for: date)
        return records.first {
            $0.missionId == missionId &&
            DailyMission.dayKey(for: $0.createdAt) == dayKey
        }
    }

    // MARK: - Delete

    func deleteRecord(_ record: MODIRecord) {
        modelContext.delete(record)
        try? modelContext.save()
        reload()
    }
}

// MARK: - Preview Support

enum MODIPreviewData {

    @MainActor
    static func makeRepository(withSampleData: Bool = false) -> (ModelContainer, MODIRepository) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: MODIRecord.self, configurations: configuration)
        let repository = MODIRepository(modelContext: container.mainContext)

        if withSampleData {
            seedSampleRecords(in: container.mainContext, mission: .mock)
            repository.reload()
        }

        return (container, repository)
    }

    @MainActor
    private static func seedSampleRecords(in context: ModelContext, mission: DailyMission) {
        let colors: [UIColor] = [.systemPink, .systemBlue, .systemTeal]
        for (index, color) in colors.enumerated() {
            let size = CGSize(width: 200, height: 200)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { context in
                color.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }

            guard let imageData = image.jpegData(compressionQuality: 0.85) else { continue }

            let record = MODIRecord(
                imageData: imageData,
                missionId: mission.collectionID,
                missionTitle: mission.title,
                missionEmoji: mission.emoji,
                createdAt: Calendar.current.date(byAdding: .day, value: -index, to: .now)!
            )
            context.insert(record)
        }
        try? context.save()
    }
}
