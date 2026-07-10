import Foundation
import Observation
import SwiftData

// MARK: - CollectionRepository

@MainActor
@Observable
final class CollectionRepository {

    private static let legacyCustomCollectionsKey = "modi.customCollections"
    private static let legacyCustomConceptsKey = "modi.customConcepts"
    private static let legacyCustomConceptsKeyPrefix = "modi.customConcepts."

    private let modelContext: ModelContext
    private(set) var collections: [MODICollection] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Bootstrap

    func bootstrap() {
        reload()
        seedSystemCollectionsIfNeeded()
        migrateLegacyCustomCollectionsIfNeeded()
        migrateLegacyCustomConceptsIfNeeded()
        linkOrphanedRecords()
        reload()
    }

    func reload() {
        let descriptor = FetchDescriptor<MODICollection>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        collections = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Fetch

    func collection(for id: UUID) -> MODICollection? {
        collections.first { $0.id == id }
    }

    var systemCollections: [MODICollection] {
        collections
            .filter { $0.collectionType == .system }
            .sorted { $0.title < $1.title }
    }

    var customCollections: [MODICollection] {
        collections
            .filter { $0.collectionType == .custom }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func records(for collection: MODICollection) -> [MODIRecord] {
        collection.sortedRecords
    }

    func photoCount(for collectionID: UUID) -> Int {
        collection(for: collectionID)?.photoCount ?? 0
    }

    /// Concept 선택 UI용: 시스템 Concept + SwiftData 커스텀 컬렉션.
    func pickerConcepts(systemConcepts: [Concept]) -> [Concept] {
        systemConcepts + customCollections.map(\.concept)
    }

    func latestRecordDate(for collectionID: UUID) -> Date? {
        collection(for: collectionID)?.latestRecordDate
    }

    // MARK: - Custom Collections

    @discardableResult
    func addCustomCollection(
        title: String,
        emoji: String,
        missionPrompt: String,
        description: String,
        themeColorHex: String,
        sourceTemplateID: String? = nil
    ) -> MODICollection {
        let collection = MODICollection(
            title: title,
            emoji: emoji,
            type: .custom,
            collectionDescription: description,
            missionPrompt: missionPrompt,
            themeColorHex: themeColorHex,
            category: .custom,
            sourceTemplateID: sourceTemplateID
        )
        modelContext.insert(collection)
        try? modelContext.save()
        reload()
        return collection
    }

    func addCustomCollection(from template: RecommendedCollectionTemplate) {
        guard !hasAddedTemplate(template.id) else { return }

        addCustomCollection(
            title: template.title,
            emoji: template.emoji,
            missionPrompt: template.missionPrompt,
            description: template.subtitle,
            themeColorHex: template.themeColorHex,
            sourceTemplateID: template.id
        )
    }

    func hasAddedTemplate(_ templateID: String) -> Bool {
        collections.contains { $0.sourceTemplateID == templateID }
    }

    // MARK: - Record Linking

    @discardableResult
    func ensureCollection(for concept: Concept) -> MODICollection {
        if let existing = collection(for: concept.id) {
            return existing
        }

        let collection = MODICollection.from(concept: concept)
        modelContext.insert(collection)
        try? modelContext.save()
        reload()
        return collection
    }

    func linkRecord(_ record: MODIRecord, to collection: MODICollection) {
        record.collection = collection
        try? modelContext.save()
        reload()
    }

    func resetForSignedOutState() {
        let descriptor = FetchDescriptor<MODICollection>()
        let allCollections = (try? modelContext.fetch(descriptor)) ?? []
        for collection in allCollections {
            modelContext.delete(collection)
        }
        try? modelContext.save()
        reload()
        seedSystemCollectionsIfNeeded()
        reload()
    }

    // MARK: - Seeding

    private func seedSystemCollectionsIfNeeded() {
        let existingIDs = Set(collections.map(\.id))

        for photoCollection in PhotoCollection.builtIn where !existingIDs.contains(photoCollection.id) {
            let collection = MODICollection.from(photoCollection: photoCollection, type: .system)
            modelContext.insert(collection)
        }

        try? modelContext.save()
    }

    /// `MissionManager`가 UserDefaults에 저장하던 커스텀 Concept를 SwiftData로 이전합니다.
    private func migrateLegacyCustomConceptsIfNeeded() {
        var legacyConcepts: [Concept] = []

        if let data = UserDefaults.standard.data(forKey: Self.legacyCustomConceptsKey),
           let decoded = try? JSONDecoder().decode([Concept].self, from: data) {
            legacyConcepts.append(contentsOf: decoded)
        }

        for key in UserDefaults.standard.dictionaryRepresentation().keys
            where key.hasPrefix(Self.legacyCustomConceptsKeyPrefix) {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let decoded = try? JSONDecoder().decode([Concept].self, from: data)
            else { continue }
            legacyConcepts.append(contentsOf: decoded)
        }

        guard !legacyConcepts.isEmpty else { return }

        let existingIDs = Set(collections.map(\.id))
        var didInsert = false

        for concept in legacyConcepts where concept.type == .custom && !existingIDs.contains(concept.id) {
            let collection = MODICollection.from(concept: concept)
            modelContext.insert(collection)
            didInsert = true
        }

        if didInsert {
            try? modelContext.save()
        }

        UserDefaults.standard.removeObject(forKey: Self.legacyCustomConceptsKey)
        for key in UserDefaults.standard.dictionaryRepresentation().keys
            where key.hasPrefix(Self.legacyCustomConceptsKeyPrefix) {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private func migrateLegacyCustomCollectionsIfNeeded() {
        guard let data = UserDefaults.standard.data(forKey: Self.legacyCustomCollectionsKey),
              let legacyCollections = try? JSONDecoder().decode([PhotoCollection].self, from: data)
        else { return }

        let existingIDs = Set(collections.map(\.id))

        for legacy in legacyCollections where !existingIDs.contains(legacy.id) {
            let collection = MODICollection.from(photoCollection: legacy, type: .custom)
            modelContext.insert(collection)
        }

        try? modelContext.save()
        UserDefaults.standard.removeObject(forKey: Self.legacyCustomCollectionsKey)
    }

    private func linkOrphanedRecords() {
        let recordDescriptor = FetchDescriptor<MODIRecord>()
        guard let records = try? modelContext.fetch(recordDescriptor) else { return }

        var didChange = false

        for record in records where record.collection == nil {
            if let collection = collection(for: record.conceptId) {
                record.collection = collection
                didChange = true
            } else if let concept = Concept.concept(for: record.conceptId) {
                let collection = ensureCollection(for: concept)
                record.collection = collection
                didChange = true
            } else {
                let collection = MODICollection(
                    id: record.conceptId,
                    title: record.conceptTitle,
                    emoji: record.conceptEmoji,
                    type: .custom,
                    collectionDescription: record.conceptTitle,
                    missionPrompt: record.conceptTitle,
                    themeColorHex: "E8ECF0",
                    category: .custom
                )
                modelContext.insert(collection)
                record.collection = collection
                didChange = true
            }
        }

        if didChange {
            try? modelContext.save()
        }
    }
}

// MARK: - Preview Support

enum CollectionPreviewData {

    @MainActor
    static func makeRepository(
        modelContext: ModelContext,
        withSampleData: Bool = false
    ) -> CollectionRepository {
        let repository = CollectionRepository(modelContext: modelContext)
        repository.bootstrap()

        if withSampleData {
            _ = repository.addCustomCollection(
                title: "카페 순간",
                emoji: "☕️",
                missionPrompt: "커피를 찍으세요",
                description: "오늘 마신 커피와 카페의 분위기를 남겨요",
                themeColorHex: "F0E8E0"
            )
        }

        return repository
    }
}
