import Foundation
import Observation
import SwiftData
import SwiftUI
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
    func saveRecord(
        image: UIImage,
        originalImage: UIImage,
        concept: Concept,
        collection: MODICollection? = nil,
        editorState: EditorState? = nil,
        isEdited: Bool = false,
        recordDate: Date? = nil
    ) throws -> MODIRecord {
        guard let imageData = image.jpegData(compressionQuality: 0.85),
              let originalData = originalImage.jpegData(compressionQuality: 0.85)
        else {
            throw RecordRepositoryError.imageEncodingFailed
        }

        let discoveryDay = Calendar.current.startOfDay(for: recordDate ?? .now)
        let record = MODIRecord(
            imageData: imageData,
            conceptId: concept.id,
            conceptTitle: concept.title,
            conceptEmoji: concept.emoji,
            recordDate: discoveryDay,
            isEdited: isEdited
        )
        record.originalImageData = originalData
        record.editorStateData = encodedEditorState(editorState)
        record.collection = collection

        modelContext.insert(record)
        try modelContext.save()
        reload()
        return record
    }

    func updateRecord(
        _ record: MODIRecord,
        image: UIImage,
        originalImage: UIImage? = nil,
        editorState: EditorState? = nil,
        isEdited: Bool = true
    ) throws {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw RecordRepositoryError.imageEncodingFailed
        }

        record.imageData = imageData
        record.isEdited = isEdited

        if let originalImage,
           let originalData = originalImage.jpegData(compressionQuality: 0.85) {
            record.originalImageData = originalData
        }

        record.editorStateData = encodedEditorState(editorState)

        try modelContext.save()
        reload()
    }

    private func encodedEditorState(_ editorState: EditorState?) -> Data? {
        guard let editorState else { return nil }
        return try? JSONEncoder().encode(editorState)
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

    func fetchRecords(for collection: MODICollection) -> [MODIRecord] {
        records.filter { $0.collection?.id == collection.id || $0.conceptId == collection.id }
            .sorted { $0.discoveryDate > $1.discoveryDate }
    }

    func fetchRecords(on date: Date) -> [MODIRecord] {
        let dayKey = DailyMission.dayKey(for: date)
        return records
            .filter { DailyMission.dayKey(for: $0.discoveryDate) == dayKey }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func photoCount(for conceptId: UUID) -> Int {
        fetchRecords(conceptId: conceptId).count
    }

    func photoCount(for collection: MODICollection) -> Int {
        fetchRecords(for: collection).count
    }

    func latestRecordDate(for collection: MODICollection) -> Date? {
        fetchRecords(for: collection).first?.discoveryDate
    }

    func hasRecord(on date: Date, conceptId: UUID) -> Bool {
        let dayKey = DailyMission.dayKey(for: date)
        return records.contains {
            $0.conceptId == conceptId &&
            DailyMission.dayKey(for: $0.discoveryDate) == dayKey
        }
    }

    func record(on date: Date, conceptId: UUID) -> MODIRecord? {
        let dayKey = DailyMission.dayKey(for: date)
        return records.first {
            $0.conceptId == conceptId &&
            DailyMission.dayKey(for: $0.discoveryDate) == dayKey
        }
    }

    // MARK: - Delete

    func deleteRecord(_ record: MODIRecord) {
        modelContext.delete(record)
        try? modelContext.save()
        reload()
    }

    func deleteAllRecords() {
        for record in records {
            modelContext.delete(record)
        }
        try? modelContext.save()
        reload()
    }
}

// MARK: - Preview Support

enum RecordPreviewData {

    @MainActor
    static func makeRepository(
        withSampleData: Bool = false,
        includeUserText: Bool = false,
        sampleDiscoveryCount: Int = 3
    ) -> (ModelContainer, RecordRepository) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema = Schema([MODIRecord.self, MODICollection.self])
        let container = try! ModelContainer(for: schema, configurations: configuration)
        let collectionRepository = CollectionRepository(modelContext: container.mainContext)
        collectionRepository.bootstrap()
        let repository = RecordRepository(modelContext: container.mainContext)

        if withSampleData {
            let collection = collectionRepository.collection(for: Concept.mock.id)
                ?? collectionRepository.ensureCollection(for: Concept.mock)
            seedSampleRecords(
                in: container.mainContext,
                concept: .mock,
                collection: collection,
                includeUserText: includeUserText,
                count: sampleDiscoveryCount
            )
            repository.reload()
        }

        return (container, repository)
    }

    @MainActor
    private static func seedSampleRecords(
        in context: ModelContext,
        concept: Concept,
        collection: MODICollection,
        includeUserText: Bool = false,
        count: Int = 3
    ) {
        let colors: [UIColor] = [.systemPink, .systemBlue, .systemTeal, .systemIndigo, .systemCyan, .systemMint]
        for index in 0..<count {
            let color = colors[index % colors.count]
            let size = CGSize(width: 200, height: 200)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { context in
                color.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }

            guard let imageData = image.jpegData(compressionQuality: 0.85) else { continue }

            let discoveryDate = Calendar.current.date(byAdding: .day, value: -index, to: .now)!
            let record = MODIRecord(
                imageData: imageData,
                conceptId: concept.id,
                conceptTitle: concept.title,
                conceptEmoji: concept.emoji,
                createdAt: discoveryDate,
                recordDate: discoveryDate,
                isEdited: index == 0
            )
            record.collection = collection

            if includeUserText, index == 0 {
                let canvasSize = CGSize(width: 300, height: 400)
                let editorState = EditorState.from(
                    elements: [
                        EditorElement(
                            type: .text(content: "오늘 하늘이 정말 예뻤어요", color: .white),
                            position: CGPoint(x: canvasSize.width / 2, y: canvasSize.height * 0.42)
                        )
                    ],
                    frameStyle: .none,
                    canvasSize: canvasSize
                )
                record.editorStateData = try? JSONEncoder().encode(editorState)
            }

            context.insert(record)
        }
        try? context.save()
    }
}
