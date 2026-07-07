import SwiftUI

struct CreateView: View {

    @Environment(CollectionStore.self) private var store

    @State private var showCompleted = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var saveErrorMessage: String?

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
            .sheet(isPresented: $showCamera) {
                ImagePicker(source: .camera) { image in
                    handleCapturedImage(image)
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showPhotoLibrary) {
                ImagePicker(source: .photoLibrary) { image in
                    handleCapturedImage(image)
                }
                .ignoresSafeArea()
            }
            .alert("사진을 저장하지 못했어요", isPresented: saveErrorIsPresented) {
                Button("확인", role: .cancel) {
                    saveErrorMessage = nil
                }
            } message: {
                Text(saveErrorMessage ?? "다시 시도해 주세요.")
            }
        }
    }

    private var saveErrorIsPresented: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
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
                mission: store.todaysMission.with(
                    isCompleted: store.isTodaysMissionCompleted
                )
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

            VStack(spacing: AppSpacing.md) {
                Button {
                    showCamera = true
                } label: {
                    Label("사진 찍기", systemImage: "camera.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("앨범에서 선택") {
                    showPhotoLibrary = true
                }
                .font(AppFont.footnote)
                .foregroundStyle(AppColor.Text.secondary)
            }

            Spacer()
        }
        .appScreenPadding()
        .appScreenBackground()
    }

    private func completedView(collection: PhotoCollection) -> some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            if let entry = store.todaysEntry() {
                MissionPhotoImage(fileName: entry.imageFileName)
                    .aspectRatio(3.0 / 4.0, contentMode: .fill)
                    .frame(maxWidth: 240)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
                    .appShadow(.medium)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppColor.Semantic.success)
            }

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

                Text(store.todaysMission.description)
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

    private func handleCapturedImage(_ image: UIImage) {
        guard store.completeTodaysMission(image: image) else {
            saveErrorMessage = "사진 파일을 저장하는 중 문제가 발생했어요."
            return
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            showCompleted = true
        }
    }
}

#Preview {
    CreateView()
        .environment(CollectionStore())
}
