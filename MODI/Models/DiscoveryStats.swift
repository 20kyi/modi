import Foundation

// MARK: - DiscoveryStats

/// SwiftData 기록에서 계산한 발견 통계.
struct DiscoveryStats: Equatable {
    let totalRecords: Int
    let activeCollections: Int
    let earnedBannerCount: Int
    let monthlyRecords: Int
    let streakDays: Int
    let lastRecordDate: Date?

    static let empty = DiscoveryStats(
        totalRecords: 0,
        activeCollections: 0,
        earnedBannerCount: 0,
        monthlyRecords: 0,
        streakDays: 0,
        lastRecordDate: nil
    )
}

// MARK: - Mock

extension DiscoveryStats {
    static let mock = DiscoveryStats(
        totalRecords: 20,
        activeCollections: 4,
        earnedBannerCount: 2,
        monthlyRecords: 8,
        streakDays: 7,
        lastRecordDate: .now
    )
}
