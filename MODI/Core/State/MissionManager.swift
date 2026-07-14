import Foundation
import Observation

// MARK: - MissionManager

@Observable
final class MissionManager {

    private static let todayMissionsKeyPrefix = "modi.todayMissions"
    private static let legacyTodayMissionsKey = "modi.todayMissions"
    private static let missionChangeCountKeyPrefix = "modi.missionChangeCount"
    private static let lastMissionChangeDateKeyPrefix = "modi.lastMissionChangeDate"
    private static let authUserIdKey = "modi_auth_userId"
    private static let guestScope = "guest"

    private var collectionRepository: CollectionRepository?
    private var todayMissions: [String: TodayMission] = [:]
    private var missionChangeCount = 0
    private var lastMissionChangeDate: Date?
    private let storage: UserDefaults
    private let catalog: SystemConceptCatalog
    private let conceptsAPIService: ConceptsAPIService
    private var activeScope: String
    private var hasPremiumAccess = false

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
        resetMissionChangeCountIfNeeded()
        migrateLegacyChangeCountIfNeeded(on: .now)
    }

    func configure(collectionRepository: CollectionRepository, hasPremiumAccess: Bool = false) {
        self.collectionRepository = collectionRepository
        self.hasPremiumAccess = hasPremiumAccess
    }

    func setPremiumAccess(_ hasPremiumAccess: Bool) {
        self.hasPremiumAccess = hasPremiumAccess
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
        let concepts = missionCandidateConcepts()

        if let existing = todayMissions[key] {
            if concepts.isEmpty || concepts.contains(where: { $0.id == existing.conceptId }) {
                return existing
            }
        }

        let selectedConcept: Concept

        if concepts.isEmpty {
            selectedConcept = missionFallbackConcept()
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

    /// 미션 변경 버튼을 표시할 수 있는지 확인합니다. 미완료 상태이고 바꿀 후보가 있을 때 true입니다.
    func canOfferMissionChange(on date: Date = .now, repository: RecordRepository) -> Bool {
        guard !isMissionCompleted(on: date, repository: repository) else { return false }
        return !rerollCandidates(on: date).isEmpty
    }

    /// 해당 날짜에 미션을 바꿀 수 있는지 확인합니다. 미완료 상태이고 일일 변경 한도 내일 때 true입니다.
    func canChangeMission(
        on date: Date = .now,
        repository: RecordRepository,
        hasPremium: Bool
    ) -> Bool {
        resetMissionChangeCountIfNeeded(on: date)
        guard canOfferMissionChange(on: date, repository: repository) else { return false }
        return remainingMissionChangeCount(on: date, hasPremium: hasPremium) > 0
    }

    /// 오늘 남은 미션 변경 횟수를 반환합니다.
    func remainingMissionChangeCount(
        on date: Date = .now,
        hasPremium: Bool
    ) -> Int {
        resetMissionChangeCountIfNeeded(on: date)
        let limit = hasPremium
            ? PremiumManager.premiumMissionChangeLimit
            : PremiumManager.freeMissionChangeLimit
        return max(0, limit - missionChangeCount)
    }

    /// 날짜가 바뀌면 오늘의 미션 변경 횟수를 초기화합니다.
    func resetMissionChangeCountIfNeeded(on date: Date = .now) {
        let today = Calendar.current.startOfDay(for: date)

        if let lastDate = lastMissionChangeDate,
           Calendar.current.isDate(lastDate, inSameDayAs: today) {
            return
        }

        missionChangeCount = 0
        lastMissionChangeDate = today
        saveMissionChangeState()
    }

    /// 미션 변경에 성공한 뒤 오늘의 변경 횟수를 1 증가시킵니다.
    func increaseMissionChangeCount(on date: Date = .now) {
        resetMissionChangeCountIfNeeded(on: date)
        missionChangeCount += 1
        lastMissionChangeDate = Calendar.current.startOfDay(for: date)
        saveMissionChangeState()
    }

    /// 오늘의 미션을 다른 Concept으로 바꿉니다.
    @discardableResult
    func changeMission(
        to concept: Concept,
        on date: Date = .now,
        repository: RecordRepository,
        hasPremium: Bool
    ) -> Bool {
        guard canChangeMission(on: date, repository: repository, hasPremium: hasPremium) else { return false }
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
        increaseMissionChangeCount(on: date)
        return true
    }

    /// 오늘 첫 미션을 제외한 컬렉션에서 랜덤으로 미션을 바꿉니다.
    @discardableResult
    func rerollMission(
        on date: Date = .now,
        repository: RecordRepository,
        hasPremium: Bool
    ) -> Concept? {
        guard let concept = rerollCandidates(on: date).randomElement() else { return nil }
        guard changeMission(to: concept, on: date, repository: repository, hasPremium: hasPremium) else { return nil }
        return concept
    }

    private func rerollCandidates(on date: Date) -> [Concept] {
        let initialConceptId = mission(for: date).initialConceptId
        return missionCandidateConcepts().filter { $0.id != initialConceptId }
    }

    private func missionCandidateConcepts() -> [Concept] {
        guard let collectionRepository else {
            return allConcepts
        }

        let includedCollectionIDs = Set(
            missionCandidateCollections(from: collectionRepository.collections).map(\.id)
        )

        guard !includedCollectionIDs.isEmpty else { return [] }
        return allConcepts.filter { includedCollectionIDs.contains($0.id) }
    }

    private func missionCandidateCollections(from collections: [MODICollection]) -> [MODICollection] {
        guard !hasPremiumAccess else {
            return collections.filter(\.isIncludedInMission)
        }

        let freeCustomSlotID = collections
            .filter { $0.collectionType == .custom }
            .sorted {
                if $0.createdAt == $1.createdAt {
                    return $0.id.uuidString < $1.id.uuidString
                }
                return $0.createdAt < $1.createdAt
            }
            .first?
            .id

        return collections.filter { collection in
            guard collection.isIncludedInMission else { return false }
            guard collection.collectionType == .custom else { return true }
            return collection.id == freeCustomSlotID
        }
    }

    private func missionFallbackConcept() -> Concept {
        systemConcepts.first ?? allConcepts.first ?? Concept.mock
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

        missionChangeCount = storage.integer(forKey: missionChangeCountKey)
        lastMissionChangeDate = storage.object(forKey: lastMissionChangeDateKey) as? Date
    }

    private func saveTodayMissions() {
        guard let data = try? JSONEncoder().encode(todayMissions) else { return }
        storage.set(data, forKey: todayMissionsKey)
    }

    private func saveMissionChangeState() {
        storage.set(missionChangeCount, forKey: missionChangeCountKey)
        if let lastMissionChangeDate {
            storage.set(lastMissionChangeDate, forKey: lastMissionChangeDateKey)
        } else {
            storage.removeObject(forKey: lastMissionChangeDateKey)
        }
    }

    private var missionChangeCountKey: String {
        "\(Self.missionChangeCountKeyPrefix).\(activeScope)"
    }

    private var lastMissionChangeDateKey: String {
        "\(Self.lastMissionChangeDateKeyPrefix).\(activeScope)"
    }

    private func migrateLegacyChangeCountIfNeeded(on date: Date) {
        let key = TodayMission.dayKey(for: date)
        guard let mission = todayMissions[key], mission.hasChangedConcept else { return }
        guard missionChangeCount == 0 else { return }

        missionChangeCount = 1
        saveMissionChangeState()
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
        resetMissionChangeCountIfNeeded()
        migrateLegacyChangeCountIfNeeded(on: .now)
    }

    func resetForSignedOutState() {
        syncSessionScope()
        todayMissions = [:]
        missionChangeCount = 0
        lastMissionChangeDate = nil
        saveMissionChangeState()
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
