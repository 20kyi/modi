import Foundation
import Observation

// MARK: - MissionManager

@Observable
final class MissionManager {

    private static let todayMissionsKeyPrefix = "modi.todayMissions"
    private static let legacyTodayMissionsKey = "modi.todayMissions"
    private static let authUserIdKey = "modi_auth_userId"
    private static let guestScope = "guest"

    private var collectionRepository: CollectionRepository?
    private var todayMissions: [String: TodayMission] = [:]
    private let storage: UserDefaults
    private let catalog: SystemConceptCatalog
    private let conceptsAPIService: ConceptsAPIService
    private var activeScope: String

    var systemConcepts: [Concept] { catalog.concepts }

    /// 커스텀 Concept는 `CollectionRepository`(SwiftData)에서 읽습니다.
    var customConcepts: [Concept] {
        collectionRepository?.customCollections.map(\.concept) ?? []
    }

    var allConcepts: [Concept] {
        systemConcepts + customConcepts
    }

    var todaysMission: TodayMission {
        mission(for: .now)
    }

    var todaysConcept: Concept? {
        concept(for: todaysMission.conceptId)
    }

    init(
        storage: UserDefaults = .standard,
        catalog: SystemConceptCatalog = .shared,
        conceptsAPIService: ConceptsAPIService = .shared
    ) {
        self.storage = storage
        self.catalog = catalog
        self.conceptsAPIService = conceptsAPIService
        activeScope = Self.currentScope(from: storage)
        load()
        migrateLegacyDataIfNeeded()
    }

    func configure(collectionRepository: CollectionRepository) {
        self.collectionRepository = collectionRepository
    }

    // MARK: - Concept Sync

    /// 서버에서 시스템 컨셉을 가져옵니다. 실패 시 캐시(또는 번들 fallback)를 유지합니다.
    func refreshSystemConcepts(accessToken: String? = nil) async {
        do {
            let responses = try await conceptsAPIService.fetchConcepts(accessToken: accessToken)
            let concepts = responses.compactMap(Concept.init(server:))
            guard !concepts.isEmpty else { return }
            catalog.apply(concepts)
        } catch {
            debugPrint("refreshSystemConcepts failed:", error.localizedDescription)
        }
    }

    // MARK: - Concept

    func concept(for id: UUID) -> Concept? {
        Concept.concept(for: id, system: systemConcepts, including: customConcepts)
    }

    func concepts(in category: CollectionCategory) -> [Concept] {
        switch category {
        case .custom:
            customConcepts
        default:
            systemConcepts.filter { $0.category == category }
        }
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
        if let data = storage.data(forKey: todayMissionsKey),
           let decoded = try? JSONDecoder().decode([String: TodayMission].self, from: data) {
            todayMissions = decoded
        } else {
            todayMissions = [:]
        }
    }

    private func saveTodayMissions() {
        guard let data = try? JSONEncoder().encode(todayMissions) else { return }
        storage.set(data, forKey: todayMissionsKey)
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
        guard storage.data(forKey: todayMissionsKey) == nil else { return }

        if let legacyTodayMissions = storage.data(forKey: Self.legacyTodayMissionsKey) {
            storage.set(legacyTodayMissions, forKey: todayMissionsKey)
        }

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
        todayMissions = [:]
    }
}

// MARK: - Mock

extension MissionManager {
    static var mock: MissionManager {
        let manager = MissionManager()
        manager.selectConcept(Concept.mock, for: .now)
        return manager
    }
}
