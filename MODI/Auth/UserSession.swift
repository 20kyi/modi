import Foundation

enum UserDisplayName {
    static let guest = "MODI Explorer"
    static let loggedInFallback = "탐험가"
}

struct UserSession: Equatable, Sendable {
    /// Apple 로그인 완료 여부 (로컬 모의 인증 기준).
    var isLoggedIn: Bool

    /// 로그인하지 않고 게스트로 사용하는 상태.
    var isGuest: Bool

    /// 백엔드 User.id (UUID).
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

    /// 홈·프로필 등에 표시할 이름. 게스트는 MODI Explorer.
    var displayName: String {
        guard isLoggedIn else { return UserDisplayName.guest }

        let trimmed = nickname?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty || trimmed == UserDisplayName.guest {
            return UserDisplayName.loggedInFallback
        }
        return trimmed
    }

    /// 게스트는 영문 브랜드 호칭이라 접미사 없음.
    var nameSuffix: String {
        isGuest ? "" : "님"
    }

    var profileTagline: String {
        isGuest ? "작은 순간을 발견하는 중" : "오늘도 발견을 기록해요"
    }

    var homeGreetingName: String {
        isGuest ? displayName : "\(displayName)님"
    }
}

