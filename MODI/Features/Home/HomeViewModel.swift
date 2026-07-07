import SwiftUI

// MARK: - ViewModel

@Observable
final class HomeViewModel {

    let userName = "영임"
    let recentDiscoveries = RecentDiscovery.mockList
    let collectionPreviews = CollectionPreviewItem.mockList

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "좋은 아침이에요"
        case 12..<18: return "좋은 오후예요"
        case 18..<22: return "좋은 저녁이에요"
        default: return "편안한 밤 되세요"
        }
    }

    func missionStatusMessage(isCompleted: Bool) -> String {
        isCompleted ? "오늘의 미션 완료 ✨" : "오늘의 발견을 시작해보세요"
    }
}
