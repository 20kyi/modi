import Foundation

enum SubscriptionPlanType: String, Codable, Sendable {
    case monthly = "MONTHLY"
    case annual = "ANNUAL"
    case lifetime = "LIFETIME"
}

enum SubscriptionStatus: String, Codable, Sendable {
    case active = "ACTIVE"
    case expired = "EXPIRED"
    case revoked = "REVOKED"
}

enum StoreEnvironment: String, Codable, Sendable {
    case sandbox = "SANDBOX"
    case production = "PRODUCTION"
    case unknown = "UNKNOWN"
}

struct SyncSubscriptionRequest: Encodable {
    let productId: String
    let planType: SubscriptionPlanType
    let transactionId: String
    let originalTransactionId: String
    let purchasedAt: String
    let expiresAt: String?
    let environment: StoreEnvironment
    let status: SubscriptionStatus
}

struct SubscriptionResponse: Decodable, Sendable {
    let id: String
    let productId: String
    let planType: SubscriptionPlanType
    let status: SubscriptionStatus
    let transactionId: String
    let originalTransactionId: String
    let purchasedAt: Date
    let expiresAt: Date?
    let environment: StoreEnvironment
    let createdAt: Date
    let updatedAt: Date
}

struct MySubscriptionResponse: Decodable, Sendable {
    let hasPremium: Bool
    let activeSubscription: SubscriptionResponse?
}

struct SubscriptionsAPIService: Sendable {
    static let shared = SubscriptionsAPIService()

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchMySubscription(accessToken: String) async throws -> MySubscriptionResponse {
        try await client.request(
            "subscriptions/me",
            accessToken: accessToken
        )
    }

    func syncSubscription(
        _ request: SyncSubscriptionRequest,
        accessToken: String
    ) async throws -> SubscriptionResponse {
        try await client.request(
            "subscriptions/me/sync",
            method: "POST",
            body: request,
            accessToken: accessToken
        )
    }
}
