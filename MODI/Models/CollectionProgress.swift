import Foundation
import Observation

// MARK: - CollectionTitle

struct CollectionTitle: Equatable, Hashable {
    let name: String
    let milestone: Int
}

// MARK: - CollectionProgress

/// 컬렉션 성장 진행 상태. Record 개수를 기준으로 자동 계산됩니다.
struct CollectionProgress: Equatable {
    let conceptID: UUID
    let totalDiscoveries: Int
    let currentTitle: CollectionTitle?
    let nextMilestone: Int?
    let discoveriesUntilNext: Int?
    let progress: Double

    static func make(conceptID: UUID, totalDiscoveries: Int) -> CollectionProgress {
        let currentTitle = ConceptTitleRegistry.currentTitle(for: conceptID, discoveries: totalDiscoveries)
        let nextMilestone = ProgressMilestone.nextMilestone(after: totalDiscoveries)
        let discoveriesUntilNext = nextMilestone.map { max(0, $0 - totalDiscoveries) }
        let progress = ProgressMilestone.segmentProgress(discoveries: totalDiscoveries)

        return CollectionProgress(
            conceptID: conceptID,
            totalDiscoveries: totalDiscoveries,
            currentTitle: currentTitle,
            nextMilestone: nextMilestone,
            discoveriesUntilNext: discoveriesUntilNext,
            progress: progress
        )
    }
}

// MARK: - ProgressMilestone

enum ProgressMilestone {
    /// 기본 마일스톤. 추후 확장 시 이 배열에 값을 추가하면 됩니다.
    static let thresholds: [Int] = [10, 30, 50, 100]

    static func currentTitleMilestone(for discoveries: Int) -> Int? {
        thresholds.filter { discoveries >= $0 }.last
    }

    static func nextMilestone(after discoveries: Int) -> Int? {
        thresholds.first { discoveries < $0 }
    }

    /// 현재 마일스톤 구간 내 진행률 (0.0 ~ 1.0).
    static func segmentProgress(discoveries: Int) -> Double {
        guard let next = nextMilestone(after: discoveries) else { return 1.0 }

        let previous = currentTitleMilestone(for: discoveries) ?? 0
        let range = next - previous
        guard range > 0 else { return 0 }

        return min(1.0, max(0, Double(discoveries - previous) / Double(range)))
    }

    static func newTitleEarned(
        previousCount: Int,
        newCount: Int,
        conceptID: UUID
    ) -> CollectionTitle? {
        let previousMilestone = currentTitleMilestone(for: previousCount)
        let newMilestone = currentTitleMilestone(for: newCount)

        guard let newMilestone, newMilestone != previousMilestone else { return nil }
        return ConceptTitleRegistry.title(for: conceptID, milestone: newMilestone)
    }

    /// 다음 단계 힌트에 쓰는 감성 이모지.
    static func hintEmoji(for nextMilestone: Int?) -> String {
        guard let nextMilestone else { return "🌿" }

        switch nextMilestone {
        case 10: return "🌱"
        case 30: return "✨"
        case 50: return "🌟"
        case 100: return "🏅"
        default: return "✨"
        }
    }
}

// MARK: - ConceptTitleRegistry

enum ConceptTitleRegistry {

    private static let customTitles: [Int: String] = [
        10: "First Keeper",
        30: "Growing Explorer",
        50: "Dedicated Collector",
        100: "Collection Master"
    ]

    private static let titlesByConceptID: [UUID: [Int: String]] = {
        var registry: [UUID: [Int: String]] = [:]

        // Color
        registry[uuid("A1000001-0000-0000-0000-000000000001")] = [
            10: "Blush Seeker", 30: "Heart Collector", 50: "Pink Wanderer", 100: "Pink Master"
        ]
        registry[uuid("A1000001-0000-0000-0000-000000000002")] = [
            10: "Blue Seeker", 30: "Blue Collector", 50: "Blue Hunter", 100: "Blue Master"
        ]
        registry[uuid("A1000001-0000-0000-0000-000000000003")] = [
            10: "Dream Seeker", 30: "Purple Collector", 50: "Dream Wanderer", 100: "Purple Master"
        ]
        registry[uuid("A1000001-0000-0000-0000-000000000004")] = [
            10: "Sun Seeker", 30: "Golden Collector", 50: "Light Hunter", 100: "Golden Master"
        ]
        registry[uuid("A1000001-0000-0000-0000-000000000005")] = [
            10: "Green Seeker", 30: "Nature Collector", 50: "Life Wanderer", 100: "Green Master"
        ]
        registry[uuid("A1000001-0000-0000-0000-000000000006")] = [
            10: "White Seeker", 30: "Still Collector", 50: "Quiet Hunter", 100: "White Master"
        ]

        // Nature
        registry[uuid("B2000001-0000-0000-0000-000000000001")] = [
            10: "Sky Watcher", 30: "Cloud Chaser", 50: "Sky Hunter", 100: "Master of Skies"
        ]
        registry[uuid("B2000001-0000-0000-0000-000000000002")] = [
            10: "Seedling Keeper", 30: "Green Explorer", 50: "Forest Wanderer", 100: "Botanical Master"
        ]
        registry[uuid("B2000001-0000-0000-0000-000000000003")] = [
            10: "Petal Finder", 30: "Bloom Collector", 50: "Garden Wanderer", 100: "Floral Master"
        ]
        registry[uuid("B2000001-0000-0000-0000-000000000004")] = [
            10: "Gentle Observer", 30: "Friend Collector", 50: "Nature Companion", 100: "Animal Whisperer"
        ]
        registry[uuid("B2000001-0000-0000-0000-000000000005")] = [
            10: "Night Watcher", 30: "Star Chaser", 50: "Twilight Hunter", 100: "Sky Master"
        ]

        return registry
    }()

    static func titleMap(for conceptID: UUID) -> [Int: String] {
        titlesByConceptID[conceptID] ?? customTitles
    }

    static func title(for conceptID: UUID, milestone: Int) -> CollectionTitle? {
        guard let name = titleMap(for: conceptID)[milestone] else { return nil }
        return CollectionTitle(name: name, milestone: milestone)
    }

    static func currentTitle(for conceptID: UUID, discoveries: Int) -> CollectionTitle? {
        guard let milestone = ProgressMilestone.currentTitleMilestone(for: discoveries) else { return nil }
        return title(for: conceptID, milestone: milestone)
    }

    static func nextTitleName(for conceptID: UUID, discoveries: Int) -> String? {
        guard let nextMilestone = ProgressMilestone.nextMilestone(after: discoveries) else { return nil }
        return title(for: conceptID, milestone: nextMilestone)?.name
    }

    private static func uuid(_ string: String) -> UUID {
        UUID(uuidString: string)!
    }
}

// MARK: - TitleCelebration

struct TitleCelebration: Equatable, Identifiable {
    let conceptID: UUID
    let collectionTitle: String
    let emoji: String
    let title: CollectionTitle
    let totalDiscoveries: Int

    var id: String { "\(conceptID.uuidString)-\(title.milestone)" }
}

// MARK: - TitleCelebrationManager

@MainActor
@Observable
final class TitleCelebrationManager {

    var pendingCelebration: TitleCelebration?

    func evaluateMilestone(
        conceptID: UUID,
        collectionTitle: String,
        collectionEmoji: String,
        previousCount: Int,
        newCount: Int
    ) {
        guard let newTitle = ProgressMilestone.newTitleEarned(
            previousCount: previousCount,
            newCount: newCount,
            conceptID: conceptID
        ) else { return }

        pendingCelebration = TitleCelebration(
            conceptID: conceptID,
            collectionTitle: collectionTitle,
            emoji: collectionEmoji,
            title: newTitle,
            totalDiscoveries: newCount
        )
    }

    func dismiss() {
        pendingCelebration = nil
    }

    static let mock: TitleCelebrationManager = {
        let manager = TitleCelebrationManager()
        manager.pendingCelebration = TitleCelebration(
            conceptID: Concept.mock.id,
            collectionTitle: "Cloud Hunter",
            emoji: "☁️",
            title: CollectionTitle(name: "Cloud Chaser", milestone: 30),
            totalDiscoveries: 30
        )
        return manager
    }()
}

// MARK: - ProfileHighestTitle

struct ProfileHighestTitle: Identifiable, Equatable {
    let id: UUID
    let title: CollectionTitle
    let collectionTitle: String
    let emoji: String
    let themeColorHex: String
    let acquiredDate: Date

    var achievementDescription: String {
        "\(title.milestone)개의 발견으로 \(title.name) 획득" // 타이틀 획득 조건
    }
}

// MARK: - Mock Data

extension CollectionProgress {
    static let mock = CollectionProgress.make(
        conceptID: Concept.mock.id,
        totalDiscoveries: 12
    )

    static let mockAtMilestone = CollectionProgress.make(
        conceptID: Concept.mock.id,
        totalDiscoveries: 30
    )

    static let mockBeginning = CollectionProgress.make(
        conceptID: Concept.mock.id,
        totalDiscoveries: 5
    )
}

extension ProfileHighestTitle {
    static let mock = ProfileHighestTitle(
        id: Concept.mock.id,
        title: CollectionTitle(name: "Cloud Chaser", milestone: 30),
        collectionTitle: "Cloud Hunter",
        emoji: "☁️",
        themeColorHex: "E4ECF4",
        acquiredDate: Calendar.current.date(byAdding: .day, value: -3, to: .now)!
    )

    static let mockList: [ProfileHighestTitle] = [
        mock,
        ProfileHighestTitle(
            id: PhotoCollection.builtIn[1].id,
            title: CollectionTitle(name: "Blue Seeker", milestone: 10),
            collectionTitle: "Blue Mood",
            emoji: "💙",
            themeColorHex: "D4E4F7",
            acquiredDate: Calendar.current.date(byAdding: .day, value: -10, to: .now)!
        )
    ]
}
