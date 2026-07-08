import SwiftUI

// MARK: - CollectionShareOptionsSheet

/// 공유 카드 미리보기와 저장·공유 액션을 제공합니다.
struct CollectionShareOptionsSheet: View {

    let image: UIImage

    @Environment(\.dismiss) private var dismiss

    @State private var showShareSheet = false
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var saveErrorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                    .appShadow(.medium)
                    .padding(.horizontal, AppSpacing.xxl)
                    .padding(.top, AppSpacing.lg)

                Spacer()

                VStack(spacing: AppSpacing.md) {
                    Button {
                        saveImage()
                    } label: {
                        Label("사진 앱에 저장", systemImage: "square.and.arrow.down")
                            .font(AppFont.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColor.Accent.primary)
                    .disabled(isSaving)

                    Button {
                        showShareSheet = true
                    } label: {
                        Label("공유하기", systemImage: "square.and.arrow.up")
                            .font(AppFont.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppColor.Accent.primary)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, AppSpacing.xxxl)
            }
            .appScreenBackground()
            .navigationTitle("컬렉션 공유")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [image])
        }
        .alert("저장 완료", isPresented: $saveSuccess) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("컬렉션 카드가 사진 앱에 저장됐어요.")
        }
        .alert("저장 실패", isPresented: saveErrorIsPresented) {
            Button("확인", role: .cancel) {
                saveErrorMessage = nil
            }
        } message: {
            Text(saveErrorMessage ?? "이미지 저장에 실패했어요.")
        }
        .overlay {
            if isSaving {
                ProgressView("저장 중…")
                    .padding(AppSpacing.xl)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.md))
            }
        }
    }

    private var saveErrorIsPresented: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }

    private func saveImage() {
        isSaving = true

        Task {
            do {
                try await PhotoLibrarySaver.saveImage(image)
                isSaving = false
                saveSuccess = true
            } catch {
                isSaving = false
                saveErrorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    CollectionShareOptionsSheet(image: UIImage(systemName: "photo")!)
}
