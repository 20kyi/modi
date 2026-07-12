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

struct CreateCustomConceptRequest: Encodable {
    let id: String
    let title: String
    let emoji: String
    let description: String
    let missionPrompt: String
    let themeColorHex: String
    let sourceTemplateId: String?
}

struct UpdateCustomConceptRequest: Encodable {
    let title: String
    let emoji: String
    let description: String
    let missionPrompt: String
    let themeColorHex: String
    let sourceTemplateId: String?
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

    func fetchMyCustomConcepts(accessToken: String) async throws -> [ServerConceptResponse] {
        try await client.request(
            "concepts/me/custom",
            method: "GET",
            accessToken: accessToken
        )
    }

    func createCustomConcept(
        _ request: CreateCustomConceptRequest,
        accessToken: String
    ) async throws -> ServerConceptResponse {
        try await client.request(
            "concepts/me/custom",
            method: "POST",
            body: request,
            accessToken: accessToken
        )
    }

    func updateCustomConcept(
        id: String,
        request: UpdateCustomConceptRequest,
        accessToken: String
    ) async throws -> ServerConceptResponse {
        try await client.request(
            "concepts/me/custom/\(id)",
            method: "PATCH",
            body: request,
            accessToken: accessToken
        )
    }

    func deleteCustomConcept(id: String, accessToken: String) async throws {
        try await client.requestVoid(
            "concepts/me/custom/\(id)",
            method: "DELETE",
            accessToken: accessToken
        )
    }
}
