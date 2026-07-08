import Foundation
import Observation

// MARK: - StreakManager

@Observable
@MainActor
final class StreakManager {

    private(set) var stats: DiscoveryStats = .empty
    private(set) var recordedDayKeys: Set<String> = []

    private let calendar = Calendar.current

    // MARK: - Refresh

    func refresh(
        records: [MODIRecord],
        collections: [MODICollection]
    ) {
        recordedDayKeys = Self.uniqueDayKeys(from: records)
        let lastRecordDate = records.map(\.discoveryDate).max()

        stats = DiscoveryStats(
            totalRecords: records.count,
            completedConcepts: Self.completedConceptCount(from: records),
            completedCollections: Self.completedCollectionCount(from: collections),
            streakDays: Self.calculateStreak(from: recordedDayKeys, calendar: calendar),
            lastRecordDate: lastRecordDate
        )
    }

    func refresh(
        recordRepository: RecordRepository,
        collectionRepository: CollectionRepository
    ) {
        refresh(
            records: recordRepository.fetchAllRecords(),
            collections: collectionRepository.collections
        )
    }

    // MARK: - Today

    var hasRecordedToday: Bool {
        recordedDayKeys.contains(DailyMission.dayKey(for: .now))
    }

    func hasRecord(on date: Date) -> Bool {
        recordedDayKeys.contains(DailyMission.dayKey(for: date))
    }

    // MARK: - Record Added

    func recordAdded(
        recordRepository: RecordRepository,
        collectionRepository: CollectionRepository
    ) {
        refresh(recordRepository: recordRepository, collectionRepository: collectionRepository)
    }

    // MARK: - Streak Calculation

    static func calculateStreak(
        from recordedDayKeys: Set<String>,
        calendar: Calendar = .current,
        referenceDate: Date = .now
    ) -> Int {
        let today = calendar.startOfDay(for: referenceDate)
        let todayKey = DailyMission.dayKey(for: today)

        let streakStart: Date
        if recordedDayKeys.contains(todayKey) {
            streakStart = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  recordedDayKeys.contains(DailyMission.dayKey(for: yesterday)) {
            streakStart = yesterday
        } else {
            return 0
        }

        var streak = 0
        var current = streakStart

        while recordedDayKeys.contains(DailyMission.dayKey(for: current)) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: current) else { break }
            current = previous
        }

        return streak
    }

    // MARK: - Helpers

    private static func uniqueDayKeys(from records: [MODIRecord]) -> Set<String> {
        Set(records.map { DailyMission.dayKey(for: $0.discoveryDate) })
    }

    private static func completedConceptCount(from records: [MODIRecord]) -> Int {
        Set(records.map(\.conceptId)).count
    }

    private static func completedCollectionCount(from collections: [MODICollection]) -> Int {
        collections.filter { ($0.records?.isEmpty == false) }.count
    }
}

// MARK: - Preview Support

extension StreakManager {
    static var mock: StreakManager {
        let manager = StreakManager()
        manager.stats = .mock
        manager.recordedDayKeys = Set(
            (0..<7).compactMap {
                Calendar.current.date(byAdding: .day, value: -$0, to: .now)
            }.map { DailyMission.dayKey(for: $0) }
        )
        return manager
    }
}
