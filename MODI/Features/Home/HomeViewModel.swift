import SwiftUI

// MARK: - Models

struct HomeItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let themeColor: Color
    let icon: String
}

// MARK: - ViewModel

@Observable
final class HomeViewModel {

    let userName = "영임"

    /// Empty by default to showcase the empty state.
    var recentItems: [HomeItem] = []

    let recommendedItems: [HomeItem] = [
        HomeItem(
            id: UUID(),
            title: "이번 달 하늘",
            subtitle: "매일 다른 하늘을 모아보세요",
            themeColor: Color(hex: "D4E4F7"),
            icon: "cloud.fill"
        ),
        HomeItem(
            id: UUID(),
            title: "창가의 빛",
            subtitle: "따뜻한 햇살이 드는 순간들",
            themeColor: Color(hex: "F0E8E0"),
            icon: "sun.max.fill"
        ),
        HomeItem(
            id: UUID(),
            title: "거리의 색",
            subtitle: "도시 속 작은 발견들",
            themeColor: Color(hex: "E0E8E4"),
            icon: "building.2.fill"
        ),
        HomeItem(
            id: UUID(),
            title: "커피 한 잔",
            subtitle: "일상의 여유를 기록해요",
            themeColor: Color(hex: "ECE4F0"),
            icon: "cup.and.saucer.fill"
        )
    ]

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "좋은 아침이에요"
        case 12..<18: return "좋은 오후예요"
        case 18..<22: return "좋은 저녁이에요"
        default: return "편안한 밤 되세요"
        }
    }
}
