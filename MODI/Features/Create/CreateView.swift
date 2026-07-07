import SwiftUI

struct CreateView: View {

    @Environment(CollectionStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showCompleted = false

    var body: some View {
        NavigationStack {
            Group {
                if let collection = store.todaysCollection {
                    missionView(collection: collection)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("오늘의 미션")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func missionView(collection: PhotoCollection) -> some View {
        if store.isTodaysMissionCompleted || showCompleted {
            completedView(collection: collection)
        } else {
            activeMissionView(collection: collection)
        }
    }

    private func activeMissionView(collection: PhotoCollection) -> some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            DailyMissionCard(
                mission: store.todaysMission,
                collection: collection
            )

            VStack(spacing: AppSpacing.sm) {
                Text("미션에 맞는 순간을 찾아보세요")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.Text.secondary)
                    .multilineTextAlignment(.center)

                Text("사진은 「\(collection.title)」 컬렉션에 저장돼요")
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.tertiary)
            }

            Button {
                store.completeTodaysMission()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    showCompleted = true
                }
            } label: {
                Label("사진 찍기", systemImage: "camera.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            Text("카메라 연동은 곧 추가될 예정이에요.\n지금은 미션 완료를 눌러 테스트해보세요.")
                .font(AppFont.caption1)
                .foregroundStyle(AppColor.Text.tertiary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .appScreenPadding()
        .appScreenBackground()
    }

    private func completedView(collection: PhotoCollection) -> some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppColor.Semantic.success)

            VStack(spacing: AppSpacing.sm) {
                Text("오늘의 미션 완료!")
                    .font(AppFont.title2)
                    .foregroundStyle(AppColor.Text.primary)

                Text("「\(collection.title)」 컬렉션에 추가됐어요")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.Text.secondary)
            }

            VStack(spacing: AppSpacing.sm) {
                Text("총 \(store.photoCount(for: collection.id))장")
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Text.primary)

                Text(store.todaysMission.prompt)
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.tertiary)
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(collection.themeColor.opacity(0.35), in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))

            Spacer()
        }
        .appScreenPadding()
        .appScreenBackground()
    }
}

#Preview {
    CreateView()
        .environment(CollectionStore())
}
