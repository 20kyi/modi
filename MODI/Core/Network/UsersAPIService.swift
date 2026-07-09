import Foundation

struct UpdateMyProfileRequest: Encodable {
    let nickname: String?
    let profileImageUrl: String?
}

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

    func updateMyNickname(_ nickname: String, accessToken: String) async throws -> AuthUserResponse {
        let request = UpdateMyProfileRequest(
            nickname: nickname,
            profileImageUrl: nil
        )

        return try await client.request(
            "users/me",
            method: "PATCH",
            body: request,
            accessToken: accessToken
        )
    }
}
