import SwiftData
import SwiftUI

// MARK: - Editor Presentation

private struct PastDiscoveryEditorPresentation: Identifiable {
    let id = UUID()
    let image: UIImage
    let concept: Concept
}

private struct PhotoSelectionContext: Identifiable {
    let id = UUID()
    let concept: Concept
}

// MARK: - PastDiscoveryFlowView

/// 지난 날짜의 발견을 추가하는 플로우: 컨셉 선택 → 사진 선택 → 편집 → 저장.
struct PastDiscoveryFlowView: View {

    let selectedDate: Date
    var onCompleted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(MissionManager.self) private var missionManager
    @Environment(RecordRepository.self) private var recordRepository
    @Environment(CollectionRepository.self) private var collectionRepository
    @Environment(StreakManager.self) private var streakManager
    @Environment(TitleCelebrationManager.self) private var titleCelebrationManager

    @State private var photoSelectionContext: PhotoSelectionContext?
    @State private var editorPresentation: PastDiscoveryEditorPresentation?
    @State private var saveErrorMessage: String?

    private var discoveryDay: Date {
        Calendar.current.startOfDay(for: selectedDate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dateHeader
                    .appScreenPadding()
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.xs)

                ConceptPickerView(concepts: missionManager.allConcepts) { concept in
                    photoSelectionContext = PhotoSelectionContext(concept: concept)
                }
            }
            .appScreenBackground()
            .navigationTitle("지난 발견 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundStyle(AppColor.Text.secondary)
                }
            }
            .sheet(item: $photoSelectionContext) { context in
                PhotoSelectionSheet(
                    concept: context.concept,
                    dateLabel: formattedDiscoveryDate,
                    showsBackButton: true
                ) { image in
                    presentEditor(image: image, concept: context.concept)
                }
            }
            .fullScreenCover(item: $editorPresentation) { presentation in
                PhotoEditorView(
                    image: presentation.image,
                    concept: presentation.concept,
                    recordDate: discoveryDay,
                    onSaved: {
                        onCompleted()
                    },
                    onSaveFailed: { _ in
                        saveErrorMessage = "사진을 저장하지 못했어요. 다시 시도해 주세요."
                    }
                )
                .environment(recordRepository)
                .environment(collectionRepository)
                .environment(streakManager)
                .environment(titleCelebrationManager)
            }
            .alert("사진을 저장하지 못했어요", isPresented: saveErrorIsPresented) {
                Button("확인", role: .cancel) {
                    saveErrorMessage = nil
                }
            } message: {
                Text(saveErrorMessage ?? "다시 시도해 주세요.")
            }
        }
        .presentationDetents([.fraction(0.65), .large])
        .presentationDragIndicator(.visible)
    }

    private var dateHeader: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(formattedDiscoveryDate)
                .font(AppFont.title3)
                .foregroundStyle(AppColor.Text.primary)

            Text("그날 발견했던 순간을 기록해요")
                .font(AppFont.footnote)
                .foregroundStyle(AppColor.Text.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var formattedDiscoveryDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: discoveryDay)
    }

    private var saveErrorIsPresented: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }

    private func presentEditor(image: UIImage, concept: Concept) {
        editorPresentation = PastDiscoveryEditorPresentation(image: image, concept: concept)
    }
}

// MARK: - Preview

#Preview {
    let (container, repository) = RecordPreviewData.makeRepository()
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()

    return PastDiscoveryFlowView(selectedDate: Calendar.current.date(byAdding: .day, value: -3, to: .now)!) {}
        .modelContainer(container)
        .environment(MissionManager.mock)
        .environment(repository)
        .environment(collectionRepository)
        .environment(StreakManager.mock)
}
