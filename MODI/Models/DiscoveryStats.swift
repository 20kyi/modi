import Foundation

// MARK: - DiscoveryStats

/// SwiftData 기록에서 계산한 발견 통계.
struct DiscoveryStats: Equatable {
    let totalRecords: Int
    let completedConcepts: Int
    let completedCollections: Int
    let streakDays: Int
    let lastRecordDate: Date?

    static let empty = DiscoveryStats(
        totalRecords: 0,
        completedConcepts: 0,
        completedCollections: 0,
        streakDays: 0,
        lastRecordDate: nil
    )
}

// MARK: - Mock

extension DiscoveryStats {
    static let mock = DiscoveryStats(
        totalRecords: 20,
        completedConcepts: 5,
        completedCollections: 4,
        streakDays: 7,
        lastRecordDate: .now
    )
}
