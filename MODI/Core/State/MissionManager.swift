import Foundation
import Observation

// MARK: - MissionManager

@Observable
final class MissionManager {

    private static let customConceptsKey = "modi.customConcepts"
    private static let todayMissionsKey = "modi.todayMissions"

    private(set) var customConcepts: [Concept] = []
    private var todayMissions: [String: TodayMission] = [:]

    var systemConcepts: [Concept] { Concept.systemConcepts }

    var allConcepts: [Concept] {
        systemConcepts + customConcepts
    }

    var todaysMission: TodayMission {
        mission(for: .now)
    }

    var todaysConcept: Concept? {
        concept(for: todaysMission.conceptId)
    }

    init() {
        load()
    }

    // MARK: - Concept

    func concept(for id: UUID) -> Concept? {
        Concept.concept(for: id, including: customConcepts)
    }

    func concepts(in category: CollectionCategory) -> [Concept] {
        switch category {
        case .custom:
            customConcepts
        default:
            systemConcepts.filter { $0.category == category }
        }
    }

    func addCustomConcept(
        title: String,
        emoji: String,
        description: String
    ) {
        let concept = Concept(
            id: UUID(),
            title: title,
            emoji: emoji,
            description: description,
            category: .custom,
            type: .custom
        )
        customConcepts.append(concept)
        saveCustomConcepts()
    }

    // MARK: - Today Mission

    /// 해당 날짜의 Concept 선택을 반환합니다. 없으면 Concept 풀에서 자동 배정합니다.
    func mission(for date: Date) -> TodayMission {
        let key = TodayMission.dayKey(for: date)

        if let existing = todayMissions[key] {
            return existing
        }

        let concepts = allConcepts
        let selectedConcept: Concept

        if concepts.isEmpty {
            selectedConcept = Concept.mock
        } else {
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
            let index = (dayOfYear - 1) % concepts.count
            selectedConcept = concepts[index]
        }

        let mission = TodayMission(conceptId: selectedConcept.id, date: date)
        todayMissions[key] = mission
        saveTodayMissions()
        return mission
    }

    /// 오늘 사용할 Concept을 직접 선택합니다.
    func selectConcept(_ concept: Concept, for date: Date = .now) {
        let key = TodayMission.dayKey(for: date)
        let mission = TodayMission(conceptId: concept.id, date: date)
        todayMissions[key] = mission
        saveTodayMissions()
    }

    // MARK: - Completion

    func isMissionCompleted(on date: Date = .now, repository: MODIRepository) -> Bool {
        let todayMission = mission(for: date)
        return repository.hasRecord(on: date, missionId: todayMission.conceptId)
    }

    func isTodaysMissionCompleted(repository: MODIRepository) -> Bool {
        isMissionCompleted(on: .now, repository: repository)
    }

    /// 기존 HomeView / DailyMissionCard와 연결하기 위한 UI 모델.
    func dailyMission(
        for date: Date = .now,
        isCompleted: Bool
    ) -> DailyMission? {
        let todayMission = mission(for: date)
        guard let concept = concept(for: todayMission.conceptId) else { return nil }

        return DailyMission(
            from: concept,
            date: date,
            isCompleted: isCompleted
        )
    }

    // MARK: - Persistence

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Self.customConceptsKey),
           let decoded = try? JSONDecoder().decode([Concept].self, from: data) {
            customConcepts = decoded
        }

        if let data = UserDefaults.standard.data(forKey: Self.todayMissionsKey),
           let decoded = try? JSONDecoder().decode([String: TodayMission].self, from: data) {
            todayMissions = decoded
        }
    }

    private func saveCustomConcepts() {
        guard let data = try? JSONEncoder().encode(customConcepts) else { return }
        UserDefaults.standard.set(data, forKey: Self.customConceptsKey)
    }

    private func saveTodayMissions() {
        guard let data = try? JSONEncoder().encode(todayMissions) else { return }
        UserDefaults.standard.set(data, forKey: Self.todayMissionsKey)
    }
}

// MARK: - Mock

extension MissionManager {
    static var mock: MissionManager {
        let manager = MissionManager()
        manager.addCustomConcept(
            title: Concept.mockCustom.title,
            emoji: Concept.mockCustom.emoji,
            description: Concept.mockCustom.description
        )
        manager.selectConcept(Concept.mock, for: .now)
        return manager
    }
}
