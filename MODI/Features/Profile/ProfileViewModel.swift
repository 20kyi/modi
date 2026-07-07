import SwiftUI

// MARK: - Settings Item

struct ProfileSettingsItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let isPremium: Bool
}

// MARK: - ViewModel

@Observable
final class ProfileViewModel {

    let profile = UserProfile.mock
    let tagline = "MODI Explorer"
    let monthlyConcept = MonthlyConcept.mock
    let collectionSummaries = ProfileCollectionSummary.mockList

    let settingsItems: [ProfileSettingsItem] = [
        ProfileSettingsItem(title: "알림 설정", icon: "bell.fill", isPremium: false),
        ProfileSettingsItem(title: "Premium", icon: "crown.fill", isPremium: true),
        ProfileSettingsItem(title: "앱 설정", icon: "gearshape.fill", isPremium: false)
    ]
}
