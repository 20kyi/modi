import SwiftUI

struct CollectionView: View {

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(AppColor.Accent.primary)

                Text("내 컬렉션")
                    .font(AppFont.title2)
                    .foregroundStyle(AppColor.Text.primary)

                Text("완성된 컬렉션이 여기에 모여요.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.Text.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .appScreenBackground()
            .navigationTitle("컬렉션")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    CollectionView()
}
