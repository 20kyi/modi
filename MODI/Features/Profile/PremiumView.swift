import SwiftUI

/// 기존 네비게이션 진입점 호환을 위한 래퍼.
struct PremiumView: View {

    var body: some View {
        ModiPlusView()
    }
}

#Preview("Premium · Light") {
    NavigationStack {
        PremiumView()
    }
    .environment(PremiumManager.shared)
    .preferredColorScheme(.light)
}
