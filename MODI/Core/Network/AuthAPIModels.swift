import Foundation

struct AppleSignInRequest: Encodable {
    let identityToken: String
    let nickname: String?
}

struct AuthUserResponse: Decodable {
    let id: String
    let nickname: String
    let profileImageUrl: String?
    let createdAt: Date
    let updatedAt: Date
}

struct AuthResponse: Decodable {
    let accessToken: String
    let user: AuthUserResponse
}
