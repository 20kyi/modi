import Foundation

struct AuthAPIService: Sendable {
    static let shared = AuthAPIService()

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func signInWithApple(identityToken: String, nickname: String?) async throws -> AuthResponse {
        let request = AppleSignInRequest(
            identityToken: identityToken,
            nickname: nickname
        )

        return try await client.request(
            "auth/apple",
            method: "POST",
            body: request
        )
    }
}
