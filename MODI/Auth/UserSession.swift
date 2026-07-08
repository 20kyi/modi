import Foundation

struct UserSession: Equatable, Sendable {
    /// Apple 로그인 완료 여부 (로컬 모의 인증 기준).
    var isLoggedIn: Bool

    /// 로그인하지 않고 게스트로 사용하는 상태.
    var isGuest: Bool

    /// 유저 식별자(추후 서버 연동 시 외부 uid로 치환 가능).
    var userId: String?

    /// 화면에 표시할 닉네임.
    var nickname: String?

    static let guest: UserSession = .init(
        isLoggedIn: false,
        isGuest: true,
        userId: nil,
        nickname: nil
    )

    static func loggedIn(userId: String, nickname: String) -> UserSession {
        .init(
            isLoggedIn: true,
            isGuest: false,
            userId: userId,
            nickname: nickname
        )
    }
}

