import AuthenticationServices
import Observation
import UIKit

enum AuthError: LocalizedError {
    case appleSignInFailed(String)

    var errorDescription: String? {
        switch self {
        case .appleSignInFailed(let message):
            return message
        }
    }
}

/// 앱 내 인증 상태(게스트/로그인)와 세션 정보를 관리합니다.
/// Sign in with Apple 완료 후 백엔드에 토큰을 교환하고 JWT를 Keychain에 저장합니다.
@MainActor
@Observable
final class AuthManager: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private(set) var session: UserSession

    private enum StorageKeys {
        static let isLoggedIn = "modi_auth_isLoggedIn"
        static let userId = "modi_auth_userId"
        static let nickname = "modi_auth_nickname"
    }

    private let storage: UserDefaults
    private let authAPIService: AuthAPIService
    private let usersAPIService: UsersAPIService

    private var appleSignInContinuation: CheckedContinuation<UserSession, Error>?
    private var activeAuthorizationController: ASAuthorizationController?

    init(
        session: UserSession,
        storage: UserDefaults = .standard,
        authAPIService: AuthAPIService = .shared,
        usersAPIService: UsersAPIService = .shared
    ) {
        self.session = session
        self.storage = storage
        self.authAPIService = authAPIService
        self.usersAPIService = usersAPIService
        super.init()
    }

    /// 실제 앱 동작 시(런타임) 저장소 상태를 로드합니다.
    convenience init(loadFromStorage: Bool) {
        if loadFromStorage {
            let loaded = Self.loadSession(from: UserDefaults.standard)
            self.init(session: loaded, storage: UserDefaults.standard)
        } else {
            self.init(session: .guest, storage: UserDefaults.standard)
        }
    }

    /// 프리뷰용 mock 인스턴스.
    static let mock: AuthManager = AuthManager(
        session: .loggedIn(userId: "mock-user", nickname: "영임")
    )

    /// API 요청에 사용할 JWT. 로그인 상태가 아니면 nil.
    var accessToken: String? {
        KeychainStore.load(for: .accessToken)
    }

    /// 런타임 진입 시 로컬 저장소를 반영합니다.
    func bootstrapFromStorage() {
        session = Self.loadSession(from: storage)
    }

    func setGuest() {
        storage.set(false, forKey: StorageKeys.isLoggedIn)
        storage.removeObject(forKey: StorageKeys.userId)
        storage.removeObject(forKey: StorageKeys.nickname)
        KeychainStore.delete(for: .accessToken)
        session = .guest
    }

    func signOut() {
        setGuest()
    }

    func deleteAccount() async throws {
        guard let accessToken else {
            setGuest()
            return
        }
        try await usersAPIService.deleteMe(accessToken: accessToken)
        setGuest()
    }

    /// Sign in with Apple 진행 후, 백엔드 인증까지 완료합니다.
    func signInWithApple() async throws -> UserSession {
        try await withCheckedThrowingContinuation { continuation in
            appleSignInContinuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            activeAuthorizationController = controller

            controller.performRequests()
        }
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        if let keyWindow = scenes
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) {
            return keyWindow
        }

        if let firstWindow = scenes.flatMap(\.windows).first {
            return firstWindow
        }

        return UIWindow()
    }

    // MARK: - ASAuthorizationControllerDelegate
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            finishAppleSignIn(with: .failure(.appleSignInFailed("인증 응답을 확인할 수 없어요.")))
            return
        }

        guard let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else {
            finishAppleSignIn(with: .failure(.appleSignInFailed("Apple 토큰을 확인할 수 없어요.")))
            return
        }

        let nickname = nicknameForAppleCredential(credential, fallbackToStorageUserId: credential.user)

        Task {
            do {
                let authResponse = try await authAPIService.signInWithApple(
                    identityToken: identityToken,
                    nickname: nickname == "MODI Explorer" ? nil : nickname
                )

                let newSession = UserSession.loggedIn(
                    userId: authResponse.user.id,
                    nickname: authResponse.user.nickname
                )

                try persist(session: newSession, accessToken: authResponse.accessToken)
                session = newSession
                finishAppleSignIn(with: .success(newSession))
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                finishAppleSignIn(with: .failure(.appleSignInFailed(message)))
            }
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let nsError = error as NSError
        let message: String
        if nsError.domain == ASAuthorizationError.errorDomain,
           let code = ASAuthorizationError.Code(rawValue: nsError.code) {
            switch code {
            case .canceled:
                message = "로그인이 취소되었어요."
            case .unknown:
                message = "Apple 로그인 설정을 확인해주세요. (앱 entitlement / 프로비저닝 프로파일)"
            case .invalidResponse:
                message = "Apple 인증 응답이 올바르지 않아요."
            case .notHandled:
                message = "Apple 로그인 요청을 처리하지 못했어요."
            case .failed:
                message = "Apple 로그인에 실패했어요."
            case .notInteractive:
                message = "지금은 Apple 로그인을 진행할 수 없어요."
            @unknown default:
                message = error.localizedDescription
            }
        } else {
            message = error.localizedDescription
        }

        finishAppleSignIn(with: .failure(.appleSignInFailed(message)))
    }

    // MARK: - Helpers
    private func finishAppleSignIn(with result: Result<UserSession, AuthError>) {
        guard let continuation = appleSignInContinuation else { return }
        appleSignInContinuation = nil
        activeAuthorizationController = nil

        continuation.resume(with: result.mapError { $0 as Error })
    }

    private func persist(session: UserSession, accessToken: String) throws {
        storage.set(session.isLoggedIn, forKey: StorageKeys.isLoggedIn)
        storage.set(session.userId, forKey: StorageKeys.userId)
        storage.set(session.nickname, forKey: StorageKeys.nickname)
        try KeychainStore.save(accessToken, for: .accessToken)
    }

    private func nicknameForAppleCredential(
        _ credential: ASAuthorizationAppleIDCredential,
        fallbackToStorageUserId: String
    ) -> String {
        if let givenName = credential.fullName?.givenName, !givenName.isEmpty {
            return givenName
        }

        if let familyName = credential.fullName?.familyName, !familyName.isEmpty {
            return familyName
        }

        if let storedUserId = storage.string(forKey: StorageKeys.userId),
           storedUserId == fallbackToStorageUserId,
           let storedNickname = storage.string(forKey: StorageKeys.nickname),
           !storedNickname.isEmpty {
            return storedNickname
        }

        return "MODI Explorer"
    }

    private static func loadSession(from storage: UserDefaults) -> UserSession {
        let isLoggedIn = storage.bool(forKey: StorageKeys.isLoggedIn)
        guard isLoggedIn else { return .guest }
        guard KeychainStore.load(for: .accessToken) != nil else { return .guest }

        let userId = storage.string(forKey: StorageKeys.userId)
        guard let userId, !userId.isEmpty else { return .guest }

        let nickname = storage.string(forKey: StorageKeys.nickname) ?? "MODI Explorer"
        return .loggedIn(userId: userId, nickname: nickname)
    }
}
