import SwiftData
import SwiftUI

// MARK: - Editor Presentation

private struct RecordEditorPresentation: Identifiable {
    let id = UUID()
    let image: UIImage
    let record: MODIRecord
}

// MARK: - RecordDetailView

struct RecordDetailView: View {

    @Environment(AuthManager.self) private var authManager
    @Environment(CollectionRepository.self) private var collectionRepository
    @Environment(RecordRepository.self) private var repository
    @Environment(StreakManager.self) private var streakManager
    @Environment(TitleCelebrationManager.self) private var titleCelebrationManager
    @Environment(\.dismiss) private var dismiss

    let record: MODIRecord
    let collection: MODICollection

    @State private var showDeleteAlert = false
    @State private var deleteErrorMessage: String?
    @State private var editorPresentation: RecordEditorPresentation?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                recordPhoto
                infoSection
                actionButtons
            }
            .appScreenPadding()
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .appScreenBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColor.Text.primary)
                }
                .accessibilityLabel("뒤로가기")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        presentEditor()
                    } label: {
                        Label("다시 꾸미기", systemImage: "wand.and.stars")
                    }

                    Button("삭제", systemImage: "trash", role: .destructive) {
                        showDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(AppColor.Text.primary)
                }
                .accessibilityLabel("메뉴")
            }
        }
        .fullScreenCover(item: $editorPresentation) { presentation in
            PhotoEditorView(
                image: presentation.image,
                concept: collection.concept,
                collection: collection,
                existingRecord: presentation.record
            ) {}
            .environment(repository)
            .environment(collectionRepository)
            .environment(streakManager)
            .environment(titleCelebrationManager)
        }
        .alert("이 기록을 삭제할까요?", isPresented: $showDeleteAlert) {
            Button("삭제", role: .destructive) {
                Task {
                    await deleteRecord()
                }
            }
            Button("취소", role: .cancel) {}
        }
        .alert("삭제 실패", isPresented: deleteFailedAlertIsPresented) {
            Button("확인", role: .cancel) {
                deleteErrorMessage = nil
            }
        } message: {
            Text(deleteErrorMessage ?? "기록을 삭제하지 못했어요.")
        }
    }

    // MARK: - Photo

    private var recordPhoto: some View {
        MODIRecordImage(record: record, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .background(AppColor.Background.secondary, in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            .appShadow(.medium)
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.sm) {
                    Text(record.conceptEmoji)
                        .font(.system(size: 28))

                    Text(record.conceptTitle)
                        .font(AppFont.title2)
                        .foregroundStyle(AppColor.Text.primary)
                }

                Text(record.discoveryDateLabel)
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
            }

            if !record.userWrittenTexts.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach(record.userWrittenTexts, id: \.self) { text in
                        Text(text)
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.Text.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .appCardStyle()
            }
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: AppSpacing.md) {
            Button {
                presentEditor()
            } label: {
                Text("✨ 다시 꾸미기")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {
                showDeleteAlert = true
            } label: {
                Text("🗑 삭제")
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Semantic.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func presentEditor() {
        guard let image = record.editingImage else { return }
        editorPresentation = RecordEditorPresentation(image: image, record: record)
    }

    private var deleteFailedAlertIsPresented: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )
    }

    private func deleteRecord() async {
        HapticManager.shared.warning()

        do {
            if authManager.session.isLoggedIn,
               let accessToken = authManager.accessToken {
                let remoteRecordID = try await resolveRemoteRecordID(for: record, accessToken: accessToken)
                try await RecordsAPIService.shared.deleteMyRecord(
                    recordId: remoteRecordID,
                    accessToken: accessToken
                )
            }

            repository.deleteRecord(record)
            collectionRepository.reload()
            streakManager.refresh(
                recordRepository: repository,
                collectionRepository: collectionRepository
            )
            ToastManager.shared.showRecordDeleted()
            dismiss()
        } catch {
            deleteErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func resolveRemoteRecordID(for record: MODIRecord, accessToken: String) async throws -> String {
        if let serverId = record.serverId {
            return serverId
        }

        // Legacy local rows may not have serverId. Find the matching server row by recordDate.
        let serverRecords = try await RecordsAPIService.shared.fetchMyRecords(accessToken: accessToken)
        let calendar = Calendar(identifier: .gregorian)
        if let matched = serverRecords.first(where: {
            calendar.isDate($0.recordDate, inSameDayAs: record.discoveryDate)
        }) {
            repository.updateServerID(for: record, serverID: matched.id)
            return matched.id
        }

        return record.id.uuidString
    }
}

// MARK: - Navigation

struct RecordNavigationValue: Hashable {
    let id: UUID
}

// MARK: - Preview

#Preview("With User Text") {
    let (container, repository) = RecordPreviewData.makeRepository(
        withSampleData: true,
        includeUserText: true
    )
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()
    let collection = collectionRepository.collection(for: Concept.mock.id)!
    let record = repository.fetchRecords(for: collection)[0]

    return NavigationStack {
        RecordDetailView(record: record, collection: collection)
    }
    .modelContainer(container)
    .environment(repository)
    .environment(collectionRepository)
    .environment(StreakManager.mock)
    .environment(AuthManager.mock)
}

#Preview("Without User Text") {
    let (container, repository) = RecordPreviewData.makeRepository(withSampleData: true)
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()
    let collection = collectionRepository.collection(for: Concept.mock.id)!
    let record = repository.fetchRecords(for: collection)[0]

    return NavigationStack {
        RecordDetailView(record: record, collection: collection)
    }
    .modelContainer(container)
    .environment(repository)
    .environment(collectionRepository)
    .environment(StreakManager.mock)
    .environment(AuthManager.mock)
}
