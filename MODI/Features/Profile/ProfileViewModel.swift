import SwiftUI

// MARK: - Settings Item

enum ProfileSettingsDestination {
    case notifications
    case premium
    case appSettings
}

struct ProfileSettingsItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let isPremium: Bool
    let destination: ProfileSettingsDestination
}

// MARK: - ViewModel

@Observable
final class ProfileViewModel {

    let profile = UserProfile.mock
    let tagline = "MODI Explorer"
    let monthlyConcept = MonthlyConcept.mock
    let collectionSummaries = ProfileCollectionSummary.mockList

    let settingsItems: [ProfileSettingsItem] = [
        ProfileSettingsItem(title: "알림 설정", icon: "bell.fill", isPremium: false, destination: .notifications),
        ProfileSettingsItem(title: "Premium", icon: "crown.fill", isPremium: true, destination: .premium),
        ProfileSettingsItem(title: "앱 설정", icon: "gearshape.fill", isPremium: false, destination: .appSettings)
    ]
}
