import Foundation

enum MODIDeepLinkDestination: Equatable {
    case todayMission
}

enum MODIDeepLink {
    static let todayMissionPath = "today-mission"

    static var todayMissionURL: URL {
        URL(string: "\(AppGroupConstants.urlScheme)://\(todayMissionPath)")!
    }

    static func destination(from url: URL) -> MODIDeepLinkDestination? {
        guard url.scheme?.lowercased() == AppGroupConstants.urlScheme else { return nil }

        switch url.host?.lowercased() ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased() {
        case todayMissionPath, "today", "mission":
            return .todayMission
        default:
            return nil
        }
    }
}
