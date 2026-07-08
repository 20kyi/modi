import SwiftData
import SwiftUI

// MARK: - Editor Presentation

private struct PastDiscoveryEditorPresentation: Identifiable {
    let id = UUID()
    let image: UIImage
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

    @State private var flowStep: FlowStep = .concept
    @State private var selectedConcept: Concept?
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var editorPresentation: PastDiscoveryEditorPresentation?
    @State private var saveErrorMessage: String?

    private enum FlowStep {
        case concept
        case photo
    }

    private var discoveryDay: Date {
        Calendar.current.startOfDay(for: selectedDate)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch flowStep {
                case .concept:
                    conceptStepView
                case .photo:
                    photoStepView
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if flowStep == .photo {
                        Button {
                            flowStep = .concept
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .accessibilityLabel("뒤로가기")
                    } else {
                        Button("닫기") {
                            dismiss()
                        }
                        .foregroundStyle(AppColor.Text.secondary)
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                PhotoLibraryPicker { image in
                    selectedImage = image
                    presentEditor()
                }
                .ignoresSafeArea()
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
            }
            .alert("사진을 저장하지 못했어요", isPresented: saveErrorIsPresented) {
                Button("확인", role: .cancel) {
                    saveErrorMessage = nil
                }
            } message: {
                Text(saveErrorMessage ?? "다시 시도해 주세요.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Concept Step

    private var conceptStepView: some View {
        VStack(spacing: 0) {
            dateHeader
                .appScreenPadding()
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.sm)

            ConceptPickerView(concepts: missionManager.allConcepts) { concept in
                selectedConcept = concept
                flowStep = .photo
            }
        }
        .appScreenBackground()
    }

    // MARK: - Photo Step

    private var photoStepView: some View {
        VStack(spacing: AppSpacing.xl) {
            dateHeader

            if let selectedConcept {
                HStack(spacing: AppSpacing.md) {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(Color(hex: selectedConcept.themeColorHex))
                        .frame(width: 48, height: 48)
                        .overlay {
                            Text(selectedConcept.emoji)
                                .font(.system(size: 24))
                        }

                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(selectedConcept.title)
                            .font(AppFont.headline)
                            .foregroundStyle(AppColor.Text.primary)

                        Text("선택한 컨셉")
                            .font(AppFont.footnote)
                            .foregroundStyle(AppColor.Text.secondary)
                    }

                    Spacer(minLength: 0)
                }
                .appCardStyle()
            }

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(AppColor.Accent.primary)

            VStack(spacing: AppSpacing.sm) {
                Text("갤러리에서 사진을 선택하세요")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.Text.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showImagePicker = true
            } label: {
                Label("갤러리에서 사진 선택", systemImage: "photo.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer()
        }
        .appScreenPadding()
        .appScreenBackground()
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

    // MARK: - Helpers

    private var navigationTitle: String {
        switch flowStep {
        case .concept: "지난 발견 추가"
        case .photo: "사진 선택"
        }
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

    private func presentEditor() {
        guard let image = selectedImage, let concept = selectedConcept else { return }
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
