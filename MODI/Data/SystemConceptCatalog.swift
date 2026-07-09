import Foundation
import Observation

/// 서버 시스템 컨셉을 메모리에 유지하고 UserDefaults 캐시와 동기화합니다.
@Observable
final class SystemConceptCatalog {
    static let shared = SystemConceptCatalog()

    private(set) var concepts: [Concept]

    private init() {
        concepts = ConceptCacheStore.load() ?? Concept.bundledFallback
    }

    func apply(_ concepts: [Concept]) {
        let systemConcepts = concepts.filter { $0.type == .system }
        guard !systemConcepts.isEmpty else { return }
        self.concepts = systemConcepts
        ConceptCacheStore.save(systemConcepts)
    }

    func resetToBundledFallback() {
        concepts = Concept.bundledFallback
    }
}
