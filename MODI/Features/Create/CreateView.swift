import SwiftData
import SwiftUI

// MARK: - Editor Presentation

private struct EditorPresentation: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct CreateView: View {

    @Environment(CollectionStore.self) private var store
    @Environment(MissionManager.self) private var missionManager
    @Environment(RecordRepository.self) private var repository
    @Environment(StreakManager.self) private var streakManager
    @Environment(TitleCelebrationManager.self) private var titleCelebrationManager

    @State private var showCompleted = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var editorPresentation: EditorPresentation?
    @State private var saveErrorMessage: String?

    private var todaysMission: DailyMission {
        missionManager.dailyMission(
            for: .now,
            isCompleted: isMissionCompleted
        ) ?? .mock
    }

    private var isMissionCompleted: Bool {
        showCompleted || missionManager.isTodaysMissionCompleted(repository: repository)
    }

    private var canChangeMission: Bool {
        !showCompleted && missionManager.canChangeMission(repository: repository)
    }

    private var todaysRecord: MODIRecord? {
        repository.fetchRecords(on: .now)
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }

    private var displayConcept: Concept? {
        if let todaysRecord,
           let concept = missionManager.concept(for: todaysRecord.conceptId) {
            return concept
        }
        return missionManager.todaysConcept
    }

    var body: some View {
        NavigationStack {
            Group {
                if let concept = displayConcept {
                    missionView(concept: concept)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("오늘의 미션")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.Background.primary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .fullScreenCover(isPresented: $showCamera) {
                if let concept = missionManager.todaysConcept {
                    CameraView(
                        todayMission: missionManager.todaysMission,
                        concept: concept,
                        mission: todaysMission,
                        onSaved: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                showCompleted = true
                            }
                        },
                        onSaveFailed: { _ in
                            saveErrorMessage = "사진 파일을 저장하는 중 문제가 발생했어요."
                        }
                    )
                    .environment(repository)
                    .environment(streakManager)
                    .environment(titleCelebrationManager)
                }
            }
            .sheet(isPresented: $showPhotoLibrary) {
                AlbumPhotoPickerSheet { image in
                    presentEditor(with: image)
                }
            }
            .fullScreenCover(item: $editorPresentation) { presentation in
                if let concept = missionManager.todaysConcept {
                    PhotoEditorView(
                        image: presentation.image,
                        concept: concept,
                        onSaved: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                showCompleted = true
                            }
                        },
                        onSaveFailed: { _ in
                            saveErrorMessage = "사진 파일을 저장하는 중 문제가 발생했어요."
                        }
                    )
                    .environment(repository)
                    .environment(streakManager)
                    .environment(titleCelebrationManager)
                }
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
    private func missionView(concept: Concept) -> some View {
        if isMissionCompleted {
            completedView(concept: concept)
        } else {
            activeMissionView(concept: concept)
        }
    }

    private func activeMissionView(concept: Concept) -> some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            DailyMissionCard(
                mission: todaysMission,
                canChangeMission: canChangeMission,
                onChangeMissionTapped: rerollMission
            )

            VStack(spacing: AppSpacing.sm) {
                Text("미션에 맞는 순간을 찾아보세요")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.Text.secondary)
                    .multilineTextAlignment(.center)

                Text("사진은 「\(concept.title)」 컨셉에 저장돼요")
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

    private func completedView(concept: Concept) -> some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            if let record = todaysRecord {
                RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                    .fill(AppColor.Background.secondary)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: 240)
                    .overlay {
                        MODIRecordImage(record: record, contentMode: .fill)
                    }
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

                Text("「\(todaysRecord?.conceptTitle ?? concept.title)」 컨셉에 추가됐어요")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.Text.secondary)
            }

            VStack(spacing: AppSpacing.sm) {
                Text("총 \(repository.photoCount(for: concept.id))장")
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Text.primary)

                Text(todaysMission.description)
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.tertiary)
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(Color(hex: concept.themeColorHex).opacity(0.35), in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))

            Spacer()
        }
        .appScreenPadding()
        .appScreenBackground()
    }

    private func presentEditor(with image: UIImage) {
        showPhotoLibrary = false

        // 시트가 완전히 닫힌 뒤 편집 화면을 띄워 흰 화면을 방지합니다.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            editorPresentation = EditorPresentation(image: image)
        }
    }

    private func rerollMission() {
        _ = missionManager.rerollMission(repository: repository)
    }
}

#Preview("Light") {
    let (container, repository) = RecordPreviewData.makeRepository()
    return CreateView()
        .modelContainer(container)
        .environment(CollectionStore())
        .environment(MissionManager.mock)
        .environment(repository)
        .environment(StreakManager.mock)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    let (container, repository) = RecordPreviewData.makeRepository()
    return CreateView()
        .modelContainer(container)
        .environment(CollectionStore())
        .environment(MissionManager.mock)
        .environment(repository)
        .environment(StreakManager.mock)
        .preferredColorScheme(.dark)
}
