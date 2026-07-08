import Foundation
import Observation
import UserNotifications

// MARK: - NotificationManager

@Observable
@MainActor
final class NotificationManager {

    static let dailyNotificationPrefix = "modi.daily.discovery"
    private static let enabledKey = "modi.notificationsEnabled"
    private static let hourKey = "modi.notificationHour"
    private static let minuteKey = "modi.notificationMinute"
    private static let schedulingHorizonDays = 14

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            if isEnabled {
                Task { await rescheduleDailyNotifications(using: pendingMissionManager) }
            } else {
                Task { await cancelDailyNotifications() }
            }
        }
    }

    var notificationHour: Int {
        didSet {
            guard notificationHour != oldValue else { return }
            UserDefaults.standard.set(notificationHour, forKey: Self.hourKey)
            if isEnabled {
                Task { await rescheduleDailyNotifications(using: pendingMissionManager) }
            }
        }
    }

    var notificationMinute: Int {
        didSet {
            guard notificationMinute != oldValue else { return }
            UserDefaults.standard.set(notificationMinute, forKey: Self.minuteKey)
            if isEnabled {
                Task { await rescheduleDailyNotifications(using: pendingMissionManager) }
            }
        }
    }

    private var pendingMissionManager: MissionManager?

    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }

    var isPermissionDenied: Bool {
        authorizationStatus == .denied
    }

    var formattedNotificationTime: String {
        var components = DateComponents()
        components.hour = notificationHour
        components.minute = notificationMinute
        guard let date = Calendar.current.date(from: components) else {
            return String(format: "%02d:%02d", notificationHour, notificationMinute)
        }
        return date.formatted(date: .omitted, time: .shortened)
    }

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        notificationHour = UserDefaults.standard.object(forKey: Self.hourKey) as? Int ?? 9
        notificationMinute = UserDefaults.standard.object(forKey: Self.minuteKey) as? Int ?? 0
    }

    // MARK: - Authorization

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            await refreshAuthorizationStatus()
            return false
        }
    }

    // MARK: - Scheduling

    func enableNotifications(missionManager: MissionManager) async -> Bool {
        pendingMissionManager = missionManager

        if isPermissionDenied {
            return false
        }

        let granted: Bool
        if authorizationStatus == .notDetermined {
            granted = await requestAuthorization()
        } else {
            granted = isAuthorized
        }

        guard granted else { return false }

        isEnabled = true
        return true
    }

    func scheduleDailyNotifications(missionManager: MissionManager) async {
        pendingMissionManager = missionManager
        guard isEnabled else { return }

        await refreshAuthorizationStatus()
        guard isAuthorized else { return }

        await cancelDailyNotifications()

        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        for dayOffset in 0..<Self.schedulingHorizonDays {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                continue
            }

            let mission = missionManager.mission(for: targetDate)
            guard let concept = missionManager.concept(for: mission.conceptId) else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
            components.hour = notificationHour
            components.minute = notificationMinute

            let content = UNMutableNotificationContent()
            content.title = Self.notificationTitle
            content.body = Self.notificationBody(for: concept)
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "\(Self.dailyNotificationPrefix).\(TodayMission.dayKey(for: targetDate))"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            try? await center.add(request)
        }
    }

    func cancelDailyNotifications() async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        let identifiers = requests
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.dailyNotificationPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func updateNotificationTime(from date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        notificationHour = components.hour ?? 9
        notificationMinute = components.minute ?? 0
    }

    func notificationTime(on referenceDate: Date = .now) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: referenceDate)
        components.hour = notificationHour
        components.minute = notificationMinute
        return Calendar.current.date(from: components) ?? referenceDate
    }

    private func rescheduleDailyNotifications(using missionManager: MissionManager?) async {
        guard let missionManager else { return }
        await scheduleDailyNotifications(missionManager: missionManager)
    }

    // MARK: - Content

    static let notificationTitle = "☀️ 오늘의 발견이 도착했어요"

    static func notificationBody(for concept: Concept) -> String {
        "오늘은 \(concept.emoji) \(concept.title)를 찾아보세요"
    }
}

// MARK: - Mock

extension NotificationManager {
    static var mock: NotificationManager {
        NotificationManager()
    }
}
