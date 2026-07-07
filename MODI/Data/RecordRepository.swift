import Foundation
import Observation
import SwiftData
import UIKit

// MARK: - RecordRepositoryError

enum RecordRepositoryError: LocalizedError {
    case imageEncodingFailed
    case missingConcept

    var errorDescription: String? {
        switch self {
        case .imageEncodingFailed:
            "사진 데이터를 변환하지 못했어요."
        case .missingConcept:
            "저장할 Concept 정보가 없어요."
        }
    }
}

// MARK: - RecordRepository

@MainActor
@Observable
final class RecordRepository {

    private let modelContext: ModelContext
    private(set) var records: [MODIRecord] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        reload()
    }

    // MARK: - Save

    @discardableResult
    func saveRecord(image: UIImage, concept: Concept, isEdited: Bool = false) throws -> MODIRecord {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw RecordRepositoryError.imageEncodingFailed
        }

        let record = MODIRecord(
            imageData: imageData,
            conceptId: concept.id,
            conceptTitle: concept.title,
            conceptEmoji: concept.emoji,
            isEdited: isEdited
        )

        modelContext.insert(record)
        try modelContext.save()
        reload()
        return record
    }

    func updateRecord(_ record: MODIRecord, image: UIImage, isEdited: Bool = true) throws {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw RecordRepositoryError.imageEncodingFailed
        }

        record.imageData = imageData
        record.isEdited = isEdited
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

    func fetchRecords(conceptId: UUID) -> [MODIRecord] {
        records.filter { $0.conceptId == conceptId }
    }

    func photoCount(for conceptId: UUID) -> Int {
        fetchRecords(conceptId: conceptId).count
    }

    func hasRecord(on date: Date, conceptId: UUID) -> Bool {
        let dayKey = DailyMission.dayKey(for: date)
        return records.contains {
            $0.conceptId == conceptId &&
            DailyMission.dayKey(for: $0.createdAt) == dayKey
        }
    }

    func record(on date: Date, conceptId: UUID) -> MODIRecord? {
        let dayKey = DailyMission.dayKey(for: date)
        return records.first {
            $0.conceptId == conceptId &&
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

enum RecordPreviewData {

    @MainActor
    static func makeRepository(withSampleData: Bool = false) -> (ModelContainer, RecordRepository) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: MODIRecord.self, configurations: configuration)
        let repository = RecordRepository(modelContext: container.mainContext)

        if withSampleData {
            seedSampleRecords(in: container.mainContext, concept: .mock)
            repository.reload()
        }

        return (container, repository)
    }

    @MainActor
    private static func seedSampleRecords(in context: ModelContext, concept: Concept) {
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
                conceptId: concept.id,
                conceptTitle: concept.title,
                conceptEmoji: concept.emoji,
                createdAt: Calendar.current.date(byAdding: .day, value: -index, to: .now)!,
                isEdited: index == 0
            )
            context.insert(record)
        }
        try? context.save()
    }
}
