import Foundation

struct UsersAPIService: Sendable {
    static let shared = UsersAPIService()

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func deleteMe(accessToken: String) async throws {
        try await client.requestVoid(
            "users/me",
            method: "DELETE",
            accessToken: accessToken
        )
    }
}
