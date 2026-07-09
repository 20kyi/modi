import Foundation

// MARK: - UserProfile

struct UserProfile: Identifiable, Equatable {
    let id: UUID
    let nickname: String
    let profileImage: String?
    let totalRecords: Int
    let totalConcepts: Int
    let streakDays: Int
}

// MARK: - MonthlyConcept

struct MonthlyConcept: Identifiable, Equatable {
    let id: UUID
    let monthLabel: String
    let title: String
    let emoji: String
    let themeColorHex: String
    let currentRecordCount: Int
}

// MARK: - ProfileCollectionSummary

struct ProfileCollectionSummary: Identifiable, Equatable {
    let id: UUID
    let title: String
    let emoji: String
    let momentCount: Int
}

// MARK: - Mock Data

extension UserProfile {
    static let mock = UserProfile(
        id: UUID(uuidString: "C3000001-0000-0000-0000-000000000001")!,
        nickname: "영임",
        profileImage: nil,
        totalRecords: 20,
        totalConcepts: 5,
        streakDays: 7
    )
}

extension MonthlyConcept {
    static let empty = MonthlyConcept(
        id: UUID(),
        monthLabel: "이번 달 MODI",
        title: "이번 달 첫 발견을 기다려요",
        emoji: "✨",
        themeColorHex: "F0F2F5",
        currentRecordCount: 0
    )

    static let mock = MonthlyConcept(
        id: UUID(uuidString: "C3000002-0000-0000-0000-000000000001")!,
        monthLabel: "7월의 MODI",
        title: "Blue Summer",
        emoji: "🔵",
        themeColorHex: "D4E4F7",
        currentRecordCount: 0
    )
}

extension ProfileCollectionSummary {
    static let mockList: [ProfileCollectionSummary] = [
        ProfileCollectionSummary(
            id: UUID(uuidString: "C3000003-0000-0000-0000-000000000001")!,
            title: "Blue Summer",
            emoji: "🔵",
            momentCount: 12
        ),
        ProfileCollectionSummary(
            id: UUID(uuidString: "C3000003-0000-0000-0000-000000000002")!,
            title: "Cloud Diary",
            emoji: "☁️",
            momentCount: 8
        )
    ]
}
