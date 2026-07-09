import Foundation
import Observation

// MARK: - MissionManager

@Observable
final class MissionManager {

    private static let customConceptsKeyPrefix = "modi.customConcepts"
    private static let todayMissionsKeyPrefix = "modi.todayMissions"
    private static let legacyCustomConceptsKey = "modi.customConcepts"
    private static let legacyTodayMissionsKey = "modi.todayMissions"
    private static let authUserIdKey = "modi_auth_userId"
    private static let guestScope = "guest"

    private(set) var customConcepts: [Concept] = []
    private var todayMissions: [String: TodayMission] = [:]
    private let storage: UserDefaults
    private var activeScope: String

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

    init(storage: UserDefaults = .standard) {
        self.storage = storage
        activeScope = Self.currentScope(from: storage)
        load()
        migrateLegacyDataIfNeeded()
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
        registerCustomConcept(concept)
    }

    func registerCustomConcept(_ concept: Concept) {
        guard concept.type == .custom,
              !customConcepts.contains(where: { $0.id == concept.id })
        else { return }

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

    /// 해당 날짜에 미션을 바꿀 수 있는지 확인합니다. 하루 1회, 미완료 상태에서만 가능합니다.
    func canChangeMission(on date: Date = .now, repository: RecordRepository) -> Bool {
        guard !isMissionCompleted(on: date, repository: repository) else { return false }
        guard !mission(for: date).hasChangedConcept else { return false }
        return !rerollCandidates(on: date).isEmpty
    }

    /// 오늘의 미션을 다른 Concept으로 바꿉니다. 하루 1회만 가능합니다.
    @discardableResult
    func changeMission(
        to concept: Concept,
        on date: Date = .now,
        repository: RecordRepository
    ) -> Bool {
        guard canChangeMission(on: date, repository: repository) else { return false }
        guard concept.id != mission(for: date).conceptId else { return false }

        let current = mission(for: date)
        let key = TodayMission.dayKey(for: date)
        let mission = TodayMission(
            conceptId: concept.id,
            initialConceptId: current.initialConceptId,
            date: date,
            hasChangedConcept: true
        )
        todayMissions[key] = mission
        saveTodayMissions()
        return true
    }

    /// 오늘 첫 미션을 제외한 컬렉션에서 랜덤으로 미션을 바꿉니다.
    @discardableResult
    func rerollMission(on date: Date = .now, repository: RecordRepository) -> Concept? {
        guard let concept = rerollCandidates(on: date).randomElement() else { return nil }
        guard changeMission(to: concept, on: date, repository: repository) else { return nil }
        return concept
    }

    private func rerollCandidates(on date: Date) -> [Concept] {
        let initialConceptId = mission(for: date).initialConceptId
        return allConcepts.filter { $0.id != initialConceptId }
    }

    // MARK: - Completion

    func isMissionCompleted(on date: Date = .now, repository: RecordRepository) -> Bool {
        // 이미 오늘 기록이 하나라도 있으면 "오늘의 미션 완료"로 간주합니다.
        !repository.fetchRecords(on: date).isEmpty
    }

    func isTodaysMissionCompleted(repository: RecordRepository) -> Bool {
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
        if let data = storage.data(forKey: customConceptsKey),
           let decoded = try? JSONDecoder().decode([Concept].self, from: data) {
            customConcepts = decoded
        } else {
            customConcepts = []
        }

        if let data = storage.data(forKey: todayMissionsKey),
           let decoded = try? JSONDecoder().decode([String: TodayMission].self, from: data) {
            todayMissions = decoded
        } else {
            todayMissions = [:]
        }
    }

    private func saveCustomConcepts() {
        guard let data = try? JSONEncoder().encode(customConcepts) else { return }
        storage.set(data, forKey: customConceptsKey)
    }

    private func saveTodayMissions() {
        guard let data = try? JSONEncoder().encode(todayMissions) else { return }
        storage.set(data, forKey: todayMissionsKey)
    }

    private var customConceptsKey: String {
        "\(Self.customConceptsKeyPrefix).\(activeScope)"
    }

    private var todayMissionsKey: String {
        "\(Self.todayMissionsKeyPrefix).\(activeScope)"
    }

    private static func currentScope(from storage: UserDefaults) -> String {
        let userId = storage.string(forKey: authUserIdKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let userId, !userId.isEmpty else { return guestScope }
        return userId
    }

    private func migrateLegacyDataIfNeeded() {
        guard storage.data(forKey: customConceptsKey) == nil,
              storage.data(forKey: todayMissionsKey) == nil
        else { return }

        if let legacyCustomConcepts = storage.data(forKey: Self.legacyCustomConceptsKey) {
            storage.set(legacyCustomConcepts, forKey: customConceptsKey)
        }

        if let legacyTodayMissions = storage.data(forKey: Self.legacyTodayMissionsKey) {
            storage.set(legacyTodayMissions, forKey: todayMissionsKey)
        }

        storage.removeObject(forKey: Self.legacyCustomConceptsKey)
        storage.removeObject(forKey: Self.legacyTodayMissionsKey)
        load()
    }

    func syncSessionScope() {
        let scope = Self.currentScope(from: storage)
        guard scope != activeScope else { return }
        activeScope = scope
        load()
    }

    func resetForSignedOutState() {
        syncSessionScope()
        customConcepts = []
        todayMissions = [:]
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
