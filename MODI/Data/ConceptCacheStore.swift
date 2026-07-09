import Foundation

/// 서버에서 받은 시스템 컨셉을 SwiftData와 분리해 UserDefaults에 캐싱합니다.
enum ConceptCacheStore {
    private static let cacheKey = "modi.systemConcepts.cache"

    static func load() -> [Concept]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode([Concept].self, from: data),
              !decoded.isEmpty
        else { return nil }
        return decoded
    }

    static func save(_ concepts: [Concept]) {
        guard !concepts.isEmpty,
              let data = try? JSONEncoder().encode(concepts)
        else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }
}
