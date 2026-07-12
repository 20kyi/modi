import Foundation

// MARK: - ProfileTopCollection

/// 프로필 헤더에 표시할 가장 많이 기록한 컬렉션.
struct ProfileTopCollection: Equatable {
    let emoji: String
    let themeColorHex: String
}

// MARK: - DiscoveryStats

/// SwiftData 기록에서 계산한 발견 통계.
struct DiscoveryStats: Equatable {
    let totalRecords: Int
    let activeCollections: Int
    let earnedBannerCount: Int
    let monthlyRecords: Int
    let streakDays: Int
    let lastRecordDate: Date?
    let topCollection: ProfileTopCollection?

    static let empty = DiscoveryStats(
        totalRecords: 0,
        activeCollections: 0,
        earnedBannerCount: 0,
        monthlyRecords: 0,
        streakDays: 0,
        lastRecordDate: nil,
        topCollection: nil
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
        lastRecordDate: .now,
        topCollection: ProfileTopCollection(emoji: "☁️", themeColorHex: "E4ECF4")
    )
}
