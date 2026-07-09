import Foundation
import SwiftUI

// MARK: - CollectionStore

/// 일일 미션 로테이션을 관리합니다. 컬렉션 데이터는 `CollectionRepository`가 담당합니다.
@Observable
final class CollectionStore {

    private static let missionsKey = "modi.dailyMissions"

    private var collectionRepository: CollectionRepository?
    private var dailyMissions: [String: DailyMission] = [:]

    var allCollections: [PhotoCollection] {
        guard let collectionRepository else {
            return PhotoCollection.builtIn
        }

        return collectionRepository.collections.map { $0.asPhotoCollection }
    }

    var customCollections: [PhotoCollection] {
        collectionRepository?.customCollections.map { $0.asPhotoCollection } ?? []
    }

    var todaysMission: DailyMission {
        mission(for: .now)
    }

    var todaysCollection: PhotoCollection? {
        collection(for: todaysMission.collectionID)
    }

    init() {
        load()
    }

    func configure(collectionRepository: CollectionRepository) {
        self.collectionRepository = collectionRepository
    }

    // MARK: - Mission

    func mission(for date: Date) -> DailyMission {
        let key = DailyMission.dayKey(for: date)

        if let existing = dailyMissions[key] {
            return existing
        }

        let collections = allCollections
        guard !collections.isEmpty else {
            let fallback = PhotoCollection.builtIn[0]
            let mission = DailyMission(from: fallback, date: date)
            dailyMissions[key] = mission
            saveMissions()
            return mission
        }

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % collections.count
        let collection = collections[index]
        let mission = DailyMission(from: collection, date: date)
        dailyMissions[key] = mission
        saveMissions()
        return mission
    }

    // MARK: - Collections

    func collection(for id: UUID) -> PhotoCollection? {
        if let modiCollection = collectionRepository?.collection(for: id) {
            return modiCollection.asPhotoCollection
        }
        return PhotoCollection.collection(for: id, including: customCollections)
    }

    func addCustomCollection(
        title: String,
        emoji: String,
        missionPrompt: String,
        description: String,
        themeColorHex: String,
        sourceTemplateID: String? = nil
    ) {
        collectionRepository?.addCustomCollection(
            title: title,
            emoji: emoji,
            missionPrompt: missionPrompt,
            description: description,
            themeColorHex: themeColorHex,
            sourceTemplateID: sourceTemplateID
        )
    }

    func addCustomCollection(from template: RecommendedCollectionTemplate) {
        collectionRepository?.addCustomCollection(from: template)
    }

    func hasAddedTemplate(_ templateID: String) -> Bool {
        collectionRepository?.hasAddedTemplate(templateID) ?? false
    }

    func availableRecommendedTemplates() -> [RecommendedCollectionTemplate] {
        RecommendedCollectionTemplate.all.filter { !hasAddedTemplate($0.id) }
    }

    // MARK: - Persistence

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Self.missionsKey),
           let decoded = try? JSONDecoder().decode([String: DailyMission].self, from: data) {
            dailyMissions = decoded
        }
    }

    private func saveMissions() {
        guard let data = try? JSONEncoder().encode(dailyMissions) else { return }
        UserDefaults.standard.set(data, forKey: Self.missionsKey)
    }

    func resetForSignedOutState() {
        dailyMissions = [:]
        UserDefaults.standard.removeObject(forKey: Self.missionsKey)
    }
}

// MARK: - PhotoCollection Bridge

extension MODICollection {
    var asPhotoCollection: PhotoCollection {
        PhotoCollection(
            id: id,
            title: title,
            emoji: emoji,
            category: collectionCategory,
            description: collectionDescription,
            missionPrompt: missionPrompt,
            themeColorHex: themeColorHex,
            isBuiltIn: collectionType == .system,
            sourceTemplateID: sourceTemplateID
        )
    }
}
