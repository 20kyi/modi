import SwiftUI

struct CreateView: View {

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(AppColor.Accent.primary)

                Text("아이템 만들기")
                    .font(AppFont.title2)
                    .foregroundStyle(AppColor.Text.primary)

                Text("나만의 컬렉션을 시작해보세요.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.Text.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .appScreenBackground()
            .navigationTitle("만들기")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    CreateView()
}
