import SwiftUI

struct CollectionPreviewView: View {

    let gallery: TodaysMissionCollectionGallery
    var onCreateTapped: (() -> Void)?

    @State private var focusedRecordID: UUID?
    @State private var autoScrollTask: Task<Void, Never>?

    private var shouldAutoScroll: Bool {
        gallery.records.count >= 3
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            header

            if gallery.records.isEmpty {
                EmptyStateView(
                    icon: "photo.on.rectangle.angled",
                    title: "아직 \(gallery.title) 사진이 없어요",
                    message: gallery.missionPrompt,
                    actionTitle: onCreateTapped == nil ? nil : "기록하기",
                    action: onCreateTapped
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.itemGap) {
                        ForEach(gallery.records, id: \.id) { record in
                            NavigationLink(value: RecordNavigationValue(id: record.id)) {
                                photoThumbnail(record)
                            }
                            .buttonStyle(.plain)
                            .id(record.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $focusedRecordID)
                .onAppear {
                    resetAutoScroll()
                }
                .onDisappear {
                    stopAutoScroll()
                }
                .onChange(of: gallery.records.map(\.id)) { _, _ in
                    resetAutoScroll()
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.xs) {
                Text("오늘의 컬렉션")
                    .font(AppFont.title3)
                    .foregroundStyle(AppColor.Text.primary)

                Text(gallery.emoji)
                    .font(AppFont.title3)
            }

            Spacer()

            if gallery.photoCount > 0 {
                NavigationLink(value: CollectionNavigationValue(id: gallery.collectionID)) {
                    HStack(spacing: AppSpacing.xxs) {
                        Text("\(gallery.photoCount)장")
                            .font(AppFont.caption1)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(AppColor.Text.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func photoThumbnail(_ record: MODIRecord) -> some View {
        Color.clear
            .frame(width: 108, height: 108)
            .background(gallery.themeColor)
            .overlay {
                MODIRecordImage(record: record, contentMode: .fill)
            }
            .modiRecordClipShape(for: record)
    }

    private func resetAutoScroll() {
        stopAutoScroll()
        focusedRecordID = gallery.records.first?.id
        startAutoScrollIfNeeded()
    }

    // 자동 스크롤 시작
    private func startAutoScrollIfNeeded() {
        guard shouldAutoScroll else { return }

        autoScrollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1)) // 1초마다 자동 스크롤

                guard !Task.isCancelled else { break }

                await MainActor.run {
                    advanceFocus()
                }
            }
        }
    }

    private func stopAutoScroll() {
        autoScrollTask?.cancel()
        autoScrollTask = nil
    }

    private func advanceFocus() {
        let recordIDs = gallery.records.map(\.id)
        guard recordIDs.count >= 3 else { return }

        guard let currentID = focusedRecordID,
              let currentIndex = recordIDs.firstIndex(of: currentID)
        else {
            focusedRecordID = recordIDs.first
            return
        }

        let nextIndex = (currentIndex + 1) % recordIDs.count
        withAnimation(.easeInOut(duration: 0.65)) {
            focusedRecordID = recordIDs[nextIndex]
        }
    }
}

#Preview("Empty") {
    CollectionPreviewView(gallery: .mockBlue)
        .appScreenPadding()
        .appScreenBackground()
}

#Preview("With Photos") {
    let (container, repository) = RecordPreviewData.makeRepository(withSampleData: true)

    return CollectionPreviewView(
        gallery: TodaysMissionCollectionGallery(
            collectionID: Concept.mock.id,
            title: Concept.mock.title,
            emoji: Concept.mock.emoji,
            themeColorHex: Concept.mock.themeColorHex,
            missionPrompt: "구름을 찾아보세요",
            records: repository.fetchAllRecords()
        )
    )
    .appScreenPadding()
    .appScreenBackground()
}
