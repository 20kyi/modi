import Foundation

struct ServerConceptResponse: Decodable {
    let id: String
    let userId: String?
    let type: String
    let title: String
    let emoji: String
    let description: String
    let category: String
    let missionPrompt: String
    let themeColorHex: String
    let sourceTemplateId: String?
    let targetCount: Int
    let createdAt: Date
    let updatedAt: Date
}

struct ConceptsAPIService: Sendable {
    static let shared = ConceptsAPIService()

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchConcepts(accessToken: String? = nil) async throws -> [ServerConceptResponse] {
        try await client.request(
            "concepts",
            method: "GET",
            accessToken: accessToken
        )
    }
}
