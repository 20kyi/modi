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
/// 현재는 Backend/API 없이 로컬에만 저장하며, 추후 Firebase/자체 서버로 확장하기 쉽도록
/// "저장/복원"을 단일 지점으로 모아둡니다.
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

    private var appleSignInContinuation: CheckedContinuation<UserSession, Error>?
    private var activeAuthorizationController: ASAuthorizationController?

    init(session: UserSession, storage: UserDefaults = .standard) {
        self.session = session
        self.storage = storage
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

    /// 런타임 진입 시 로컬 저장소를 반영합니다.
    func bootstrapFromStorage() {
        session = Self.loadSession(from: storage)
    }

    func setGuest() {
        storage.set(false, forKey: StorageKeys.isLoggedIn)
        storage.removeObject(forKey: StorageKeys.userId)
        storage.removeObject(forKey: StorageKeys.nickname)
        session = .guest
    }

    /// Sign in with Apple 진행 후, 성공 시 로컬에 사용자 정보를 저장합니다.
    func signInWithApple() async throws -> UserSession {
        try await withCheckedThrowingContinuation { continuation in
            appleSignInContinuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            activeAuthorizationController = controller // 컨트롤러가 해제되지 않도록 보관

            controller.performRequests()
        }
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // iOS 버전에 따라 UIWindowScene.windows/keyWindow 접근이 흔들릴 수 있어,
        // 호환성을 위해 UIApplication의 key window를 사용합니다.
        return UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIWindow()
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

        let userId = credential.user

        // fullName/email은 첫 로그인 시점에만 내려오는 경우가 많으므로,
        // 없으면 기존 저장된 닉네임 또는 기본 닉네임을 사용합니다.
        let nickname = nicknameForAppleCredential(credential, fallbackToStorageUserId: userId)
        let newSession = UserSession.loggedIn(userId: userId, nickname: nickname)

        persist(session: newSession)
        session = newSession
        finishAppleSignIn(with: .success(newSession))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        finishAppleSignIn(with: .failure(.appleSignInFailed(error.localizedDescription)))
    }

    // MARK: - Helpers
    private func finishAppleSignIn(with result: Result<UserSession, AuthError>) {
        guard let continuation = appleSignInContinuation else { return }
        appleSignInContinuation = nil
        activeAuthorizationController = nil

        continuation.resume(with: result.mapError { $0 as Error })
    }

    private func persist(session: UserSession) {
        storage.set(session.isLoggedIn, forKey: StorageKeys.isLoggedIn)
        storage.set(session.userId, forKey: StorageKeys.userId)
        storage.set(session.nickname, forKey: StorageKeys.nickname)
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

        let userId = storage.string(forKey: StorageKeys.userId)
        guard let userId, !userId.isEmpty else { return .guest }

        let nickname = storage.string(forKey: StorageKeys.nickname) ?? "MODI Explorer"
        return .loggedIn(userId: userId, nickname: nickname)
    }
}

