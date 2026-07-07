import Foundation
import SwiftUI

// MARK: - CollectionStore

@Observable
final class CollectionStore {

    private static let customCollectionsKey = "modi.customCollections"
    private static let missionsKey = "modi.dailyMissions"

    private(set) var customCollections: [PhotoCollection] = []
    private var dailyMissions: [String: DailyMission] = [:]

    var allCollections: [PhotoCollection] {
        PhotoCollection.builtIn + customCollections
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
        PhotoCollection.collection(for: id, including: customCollections)
    }

    func addCustomCollection(
        title: String,
        emoji: String,
        missionPrompt: String,
        description: String,
        themeColorHex: String,
        sourceTemplateID: String? = nil
    ) {
        let collection = PhotoCollection(
            id: UUID(),
            title: title,
            emoji: emoji,
            category: .custom,
            description: description,
            missionPrompt: missionPrompt,
            themeColorHex: themeColorHex,
            isBuiltIn: false,
            sourceTemplateID: sourceTemplateID
        )
        customCollections.append(collection)
        saveCustomCollections()
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
        customCollections.contains { $0.sourceTemplateID == templateID }
    }

    func availableRecommendedTemplates() -> [RecommendedCollectionTemplate] {
        RecommendedCollectionTemplate.all.filter { !hasAddedTemplate($0.id) }
    }

    // MARK: - Persistence

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Self.customCollectionsKey),
           let decoded = try? JSONDecoder().decode([PhotoCollection].self, from: data) {
            customCollections = decoded
        }

        if let data = UserDefaults.standard.data(forKey: Self.missionsKey),
           let decoded = try? JSONDecoder().decode([String: DailyMission].self, from: data) {
            dailyMissions = decoded
        }
    }

    private func saveCustomCollections() {
        guard let data = try? JSONEncoder().encode(customCollections) else { return }
        UserDefaults.standard.set(data, forKey: Self.customCollectionsKey)
    }

    private func saveMissions() {
        guard let data = try? JSONEncoder().encode(dailyMissions) else { return }
        UserDefaults.standard.set(data, forKey: Self.missionsKey)
    }
}
