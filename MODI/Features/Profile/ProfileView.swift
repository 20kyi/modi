import SwiftUI

struct ProfileView: View {

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "person.circle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(AppColor.Accent.primary)

                Text("프로필")
                    .font(AppFont.title2)
                    .foregroundStyle(AppColor.Text.primary)

                Text("내 정보와 설정을 관리해요.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.Text.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .appScreenBackground()
            .navigationTitle("프로필")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ProfileView()
}
