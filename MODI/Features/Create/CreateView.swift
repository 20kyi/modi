import SwiftData
import SwiftUI

// MARK: - Editor Presentation

private struct EditorPresentation: Identifiable {
    let id = UUID()
    let image: UIImage
    var existingRecord: MODIRecord?
}

struct CreateView: View {

    @Environment(CollectionStore.self) private var store
    @Environment(AuthManager.self) private var authManager
    @Environment(CollectionRepository.self) private var collectionRepository
    @Environment(MissionManager.self) private var missionManager
    @Environment(RecordRepository.self) private var repository
    @Environment(StreakManager.self) private var streakManager
    @Environment(TitleCelebrationManager.self) private var titleCelebrationManager
    @Environment(PremiumManager.self) private var premiumManager

    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var editorPresentation: EditorPresentation?
    @State private var saveErrorMessage: String?
    @State private var deleteErrorMessage: String?
    @State private var showDeleteAlert = false
    @State private var isShowingMissionChangeLimitSheet = false
    @State private var isShowingPremium = false

    private var todaysMission: DailyMission {
        missionManager.dailyMission(
            for: .now,
            isCompleted: isMissionCompleted
        ) ?? .mock
    }

    private var isMissionCompleted: Bool {
        missionManager.isTodaysMissionCompleted(repository: repository)
    }

    private var canOfferMissionChange: Bool {
        missionManager.canOfferMissionChange(repository: repository)
    }

    private var canPerformMissionChange: Bool {
        missionManager.canChangeMission(
            repository: repository,
            hasPremium: premiumManager.hasPremium
        )
    }

    private var showsMissionChangeButton: Bool {
        if premiumManager.hasPremium {
            return canPerformMissionChange
        }
        return canOfferMissionChange
    }

    private var remainingMissionChanges: Int? {
        guard canOfferMissionChange else { return nil }
        return missionManager.remainingMissionChangeCount(hasPremium: premiumManager.hasPremium)
    }

    private var todaysRecord: MODIRecord? {
        repository.record(on: .now, conceptId: missionManager.todaysMission.collectionId)
    }

    private var displayConcept: Concept? {
        return missionManager.todaysConcept
    }

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
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
                        onSaved: syncMissionCompletion,
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
                        collection: presentation.existingRecord?.collection
                            ?? presentation.existingRecord.flatMap { collectionRepository.collection(for: $0.conceptId) },
                        existingRecord: presentation.existingRecord,
                        onSaved: syncMissionCompletion,
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
            .alert("오늘의 사진을 삭제할까요?", isPresented: $showDeleteAlert) {
                Button("삭제", role: .destructive) {
                    if let todaysRecord {
                        Task {
                            await deleteRecord(todaysRecord)
                        }
                    }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("삭제한 사진은 복구할 수 없어요.")
            }
            .alert("삭제 실패", isPresented: deleteErrorIsPresented) {
                Button("확인", role: .cancel) {
                    deleteErrorMessage = nil
                }
            } message: {
                Text(deleteErrorMessage ?? "사진을 삭제하지 못했어요.")
            }
            .navigationDestination(isPresented: $isShowingPremium) {
                PremiumView()
            }
            .sheet(isPresented: $isShowingMissionChangeLimitSheet) {
                MissionChangeLimitSheet(
                    onShowPremium: {
                        isShowingMissionChangeLimitSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            isShowingPremium = true
                        }
                    }
                )
            }
        }
    }

    private var saveErrorIsPresented: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }

    private var deleteErrorIsPresented: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
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
        Group {
            if isPad {
                iPadActiveMissionView(concept: concept)
            } else {
                iPhoneActiveMissionView(concept: concept)
            }
        }
        .appScreenBackground()
    }

    private func iPhoneActiveMissionView(concept: Concept) -> some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            DailyMissionCard(
                mission: todaysMission,
                canOfferMissionChange: canOfferMissionChange,
                showsMissionChangeButton: showsMissionChangeButton,
                hasPremium: premiumManager.hasPremium,
                remainingMissionChanges: remainingMissionChanges,
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
    }

    private func iPadActiveMissionView(concept: Concept) -> some View {
        GeometryReader { proxy in
            let usesSingleColumn = proxy.size.width < 760

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                    iPadCreateHeader

                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        HStack(alignment: .center) {
                            Text("오늘의 미션")
                                .font(AppFont.title3)
                                .foregroundStyle(AppColor.Text.primary)

                            Spacer()

                            Text(todaysMission.emoji)
                                .font(.system(size: 28))
                        }

                        iPadMissionCard
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        Text("무엇을 기록할까요?")
                            .font(AppFont.title3)
                            .foregroundStyle(AppColor.Text.primary)

                        recordChoiceSection(usesSingleColumn: usesSingleColumn)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        Text("오늘 담길 컬렉션")
                            .font(AppFont.title3)
                            .foregroundStyle(AppColor.Text.primary)

                        iPadCollectionCard(concept: concept, usesFullWidth: usesSingleColumn)
                    }
                }
                .padding(.horizontal, usesSingleColumn ? AppSpacing.xxxl : AppSpacing.huge)
                .padding(.vertical, AppSpacing.xxl)
                .frame(maxWidth: usesSingleColumn ? 620 : 860, alignment: .leading)
            }
        }
    }

    private var iPadCreateHeader: some View {
        VStack(spacing: AppSpacing.lg) {
            HStack(spacing: AppSpacing.md) {
                Text("오늘의 기록")
                    .font(AppFont.Rounded.title)
                    .foregroundStyle(AppColor.Text.primary)

                Spacer()

                Button {
                } label: {
                    Image(systemName: "bell")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColor.Text.secondary)
                        .frame(width: 40, height: 40)
                        .background(AppColor.Surface.card, in: Circle())
                }
                .buttonStyle(.plain)
                .hoverEffect(.highlight)

                Button {
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColor.Text.secondary)
                        .frame(width: 40, height: 40)
                        .background(AppColor.Surface.card, in: Circle())
                }
                .buttonStyle(.plain)
                .hoverEffect(.highlight)
            }

            Divider()
                .background(AppColor.Border.subtle)
        }
    }

    private var iPadMissionCard: some View {
        HStack(alignment: .center, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(todaysMission.title)
                    .font(AppFont.title2)
                    .foregroundStyle(AppColor.Text.primary)

                Text(todaysMission.description)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppSpacing.lg)

            Button {
                showCamera = true
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Text("시작하기")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .font(AppFont.headline)
                .foregroundStyle(AppColor.Accent.highlight)
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
        }
        .padding(AppSpacing.xxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppColor.emojiBackground(from: todaysMission.themeColorHex).opacity(0.36),
            in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .strokeBorder(AppColor.Border.default, lineWidth: 1)
        }
        .appShadow(.subtle)
    }

    private func iPadRecordChoiceCard(
        emoji: String,
        title: String,
        usesFullWidth: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Text(emoji)
                    .font(.system(size: 28))

                Text(title)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Text.primary)

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.xl)
            .frame(maxWidth: usesFullWidth ? .infinity : 210, alignment: .leading)
            .frame(minHeight: 104)
            .background(AppColor.Surface.card, in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .strokeBorder(AppColor.Border.default, lineWidth: 1)
            }
            .appShadow(.subtle)
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
    }

    @ViewBuilder
    private func recordChoiceSection(usesSingleColumn: Bool) -> some View {
        if usesSingleColumn {
            VStack(spacing: AppSpacing.md) {
                iPadRecordChoiceCard(
                    emoji: "📷",
                    title: "사진 찍기",
                    usesFullWidth: true,
                    action: { showCamera = true }
                )

                iPadRecordChoiceCard(
                    emoji: "🖼",
                    title: "앨범 선택",
                    usesFullWidth: true,
                    action: { showPhotoLibrary = true }
                )
            }
        } else {
            HStack(spacing: AppSpacing.lg) {
                iPadRecordChoiceCard(
                    emoji: "📷",
                    title: "사진 찍기",
                    action: { showCamera = true }
                )

                iPadRecordChoiceCard(
                    emoji: "🖼",
                    title: "앨범 선택",
                    action: { showPhotoLibrary = true }
                )
            }
        }
    }

    private func iPadCollectionCard(concept: Concept, usesFullWidth: Bool = false) -> some View {
        HStack(spacing: AppSpacing.md) {
            Text(concept.emoji)
                .font(.system(size: 28))

            Text(concept.title)
                .font(AppFont.headline)
                .foregroundStyle(AppColor.Text.primary)

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: usesFullWidth ? .infinity : 520, alignment: .leading)
        .background(AppColor.Surface.card, in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .strokeBorder(AppColor.Border.default, lineWidth: 1)
        }
        .appShadow(.subtle)
    }

    private func completedView(concept: Concept) -> some View {
        if isPad {
            return AnyView(iPadCompletedView(concept: concept))
        }

        return AnyView(iPhoneCompletedView(concept: concept))
    }

    private func iPhoneCompletedView(concept: Concept) -> some View {
        let palette = AppColor.themePalette(from: concept.themeColorHex)

        return VStack(spacing: AppSpacing.xl) {
            Spacer()

            if let record = todaysRecord {
                VStack(spacing: AppSpacing.md) {
                    completedRecordPhoto(record, contentMode: .fill)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 240)
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(palette.completedForeground)
                    .symbolEffect(.bounce)
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
            .background(palette.softFill, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .strokeBorder(palette.accent.opacity(0.28), lineWidth: 1)
            }

            Spacer()
        }
        .appScreenPadding()
        .appScreenBackground()
    }

    private func iPadCompletedView(concept: Concept) -> some View {
        let palette = AppColor.themePalette(from: concept.themeColorHex)

        return GeometryReader { proxy in
            let usesSingleColumn = proxy.size.width < 760
            let maxContentWidth: CGFloat = usesSingleColumn ? 620 : 680
            let maxPhotoSize: CGFloat = usesSingleColumn ? 360 : 420

            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    if let record = todaysRecord {
                        completedRecordPhoto(record, contentMode: .fit)
                            .frame(maxWidth: maxPhotoSize, maxHeight: maxPhotoSize)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 96))
                            .foregroundStyle(palette.completedForeground)
                    }

                    completedInfoSection(concept: concept, palette: palette)

                    if let record = todaysRecord {
                        completedPhotoActions(for: record)
                            .frame(maxWidth: 360)
                    }
                }
                .padding(.horizontal, usesSingleColumn ? AppSpacing.xxxl : AppSpacing.huge)
                .padding(.vertical, AppSpacing.xxl)
                .frame(maxWidth: maxContentWidth)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .center)
            }
        }
        .appScreenBackground()
    }

    private func completedRecordPhoto(
        _ record: MODIRecord,
        contentMode: ContentMode
    ) -> some View {
        MODIRecordImage(record: record, contentMode: contentMode)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .strokeBorder(AppColor.Border.default.opacity(0.45), lineWidth: 1)
            }
            .shadow(color: AppShadow.medium.color, radius: AppShadow.medium.radius, x: 0, y: AppShadow.medium.yOffset)
    }

    private func completedInfoSection(
        concept: Concept,
        palette: AppColor.ThemePalette
    ) -> some View {
        VStack(alignment: .center, spacing: AppSpacing.xl) {
            Text("오늘의 미션 완료!")
                .font(AppFont.Rounded.title)
                .foregroundStyle(AppColor.Text.primary)
                .multilineTextAlignment(.center)

            Text("「\(todaysRecord?.conceptTitle ?? concept.title)」 컬렉션에 오늘의 순간이 저장됐어요.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.Text.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .center, spacing: AppSpacing.sm) {
                Text("총 \(repository.photoCount(for: concept.id))장")
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Text.primary)

                Text(todaysMission.description)
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(palette.softFill, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))

            completedCollectionImageGrid(for: concept)
        }
    }

    @ViewBuilder
    private func completedCollectionImageGrid(for concept: Concept) -> some View {
        let records = repository.fetchRecords(conceptId: concept.id)
            .sorted { $0.discoveryDate > $1.discoveryDate }

        if !records.isEmpty {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 72, maximum: 96), spacing: AppSpacing.sm)],
                spacing: AppSpacing.sm
            ) {
                ForEach(records.prefix(6), id: \.id) { record in
                    MODIRecordImage(record: record, contentMode: .fill)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        .shadow(color: AppShadow.subtle.color, radius: AppShadow.subtle.radius, x: 0, y: AppShadow.subtle.yOffset)
                }
            }
        }
    }

    private func completedPhotoActions(for record: MODIRecord) -> some View {
        HStack(spacing: AppSpacing.md) {
            Button {
                presentEditor(for: record)
            } label: {
                Label("수정하기", systemImage: "pencil")
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Accent.highlight)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        AppColor.Accent.highlight.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)

            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("삭제하기", systemImage: "trash")
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Semantic.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        AppColor.Semantic.error.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
        }
    }

    private func presentEditor(with image: UIImage) {
        showPhotoLibrary = false

        // 시트가 완전히 닫힌 뒤 편집 화면을 띄워 흰 화면을 방지합니다.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            editorPresentation = EditorPresentation(image: image)
        }
    }

    private func presentEditor(for record: MODIRecord) {
        guard let image = record.editingImage else { return }
        editorPresentation = EditorPresentation(
            image: image,
            existingRecord: record
        )
    }

    private func rerollMission() {
        if missionManager.canChangeMission(
            repository: repository,
            hasPremium: premiumManager.hasPremium
        ) {
            _ = missionManager.rerollMission(
                repository: repository,
                hasPremium: premiumManager.hasPremium
            )
        } else if !premiumManager.hasPremium {
            isShowingMissionChangeLimitSheet = true
        }
    }

    private func deleteRecord(_ record: MODIRecord) async {
        HapticManager.shared.warning()

        do {
            try await deleteRemoteRecordIfNeeded(record)
            repository.deleteRecord(record)
            collectionRepository.reload()
            streakManager.refresh(
                recordRepository: repository,
                collectionRepository: collectionRepository
            )
            syncMissionCompletion()
            ToastManager.shared.showRecordDeleted()
        } catch {
            deleteErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func deleteRemoteRecordIfNeeded(_ record: MODIRecord) async throws {
        guard authManager.session.isLoggedIn,
              let accessToken = authManager.accessToken
        else { return }

        let remoteRecordID = try await resolveRemoteRecordID(for: record, accessToken: accessToken)
        try await RecordsAPIService.shared.deleteMyRecord(
            recordId: remoteRecordID,
            accessToken: accessToken
        )
    }

    private func resolveRemoteRecordID(for record: MODIRecord, accessToken: String) async throws -> String {
        if let serverId = record.serverId {
            return serverId
        }

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

    private func syncMissionCompletion() {
        missionManager.syncCompletionStatus(repository: repository)
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
        .environment(PremiumManager.shared)
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
        .environment(PremiumManager.shared)
        .preferredColorScheme(.dark)
}
