import Foundation

struct ServerRecordResponse: Decodable {
    let id: String
    let conceptId: String
    let conceptTitle: String
    let conceptEmoji: String
    let originalImageUrl: String
    let editedImageUrl: String
    let recordDate: Date
    let isEdited: Bool
    let createdAt: Date
    let updatedAt: Date
}

struct UpsertRecordRequest: Encodable {
    let conceptId: String
    let conceptTitle: String
    let conceptEmoji: String
    let originalImageUrl: String
    let editedImageUrl: String
    let recordDate: String
    let isEdited: Bool
}

struct RecordsAPIService: Sendable {
    static let shared = RecordsAPIService()

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchMyRecords(accessToken: String) async throws -> [ServerRecordResponse] {
        try await client.request(
            "records/me",
            method: "GET",
            accessToken: accessToken
        )
    }

    func upsertMyRecord(_ request: UpsertRecordRequest, accessToken: String) async throws -> ServerRecordResponse {
        try await client.request(
            "records/me",
            method: "POST",
            body: request,
            accessToken: accessToken
        )
    }
}
