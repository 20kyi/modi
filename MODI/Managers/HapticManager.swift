import UIKit

// MARK: - HapticManager

/// 앱 전역 햅틱 피드백을 한 곳에서 관리합니다.
/// 기록 저장, 배지 획득, 공유 완료, 삭제 확인에만 사용합니다.
@MainActor
final class HapticManager {

    static let shared = HapticManager()

    private static let enabledKey = "settings.app.hapticFeedbackEnabled"
    private static let dedupeWindow: TimeInterval = 0.35

    private var lastFiredAt: [String: Date] = [:]
    private let successGenerator = UINotificationFeedbackGenerator()
    private let warningGenerator = UINotificationFeedbackGenerator()
    private let achievementImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)

    private init() {
        prepareGenerators()
    }

    var isEnabled: Bool {
        guard UserDefaults.standard.object(forKey: Self.enabledKey) != nil else {
            return true
        }
        return UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    /// 기록 저장 완료, 공유 완료
    func success() {
        playSuccess(emphasized: false, key: "success")
    }

    /// 배지 획득 — 일반 저장보다 강조된 success 피드백
    func badgeSuccess() {
        playSuccess(emphasized: true, key: "badgeSuccess")
    }

    /// 삭제 최종 승인
    func warning() {
        guard shouldPlay(key: "warning") else { return }
        warningGenerator.notificationOccurred(.warning)
        prepareGenerators()
    }

    /// 설정에서 햅틱 피드백을 켰을 때 미리보기용 피드백
    func previewEnabledFeedback() {
        successGenerator.notificationOccurred(.success)
        prepareGenerators()
    }

    private func playSuccess(emphasized: Bool, key: String) {
        guard shouldPlay(key: key) else { return }

        successGenerator.notificationOccurred(.success)

        if emphasized {
            achievementImpactGenerator.impactOccurred(intensity: 1.0)
        }

        prepareGenerators()
    }

    private func shouldPlay(key: String) -> Bool {
        guard isEnabled else { return false }

        let now = Date()
        if let last = lastFiredAt[key], now.timeIntervalSince(last) < Self.dedupeWindow {
            return false
        }

        lastFiredAt[key] = now
        return true
    }

    private func prepareGenerators() {
        successGenerator.prepare()
        warningGenerator.prepare()
        achievementImpactGenerator.prepare()
    }
}
