import SwiftData
import SwiftUI

// MARK: - DiscoveryDaySheet

/// 캘린더에서 선택한 날짜의 발견 기록을 보여주거나, 지난 발견 추가를 시작합니다.
struct DiscoveryDaySheet: View {

    let date: Date
    let records: [MODIRecord]
    var onAddPastDiscovery: () -> Void

    @Environment(CollectionRepository.self) private var collectionRepository
    @Environment(\.dismiss) private var dismiss

    private let calendar = Calendar.current

    private var discoveryDay: Date {
        calendar.startOfDay(for: date)
    }

    private var isToday: Bool {
        calendar.isDate(discoveryDay, inSameDayAs: .now)
    }

    private var isFuture: Bool {
        discoveryDay > calendar.startOfDay(for: .now)
    }

    private var canAddPastDiscovery: Bool {
        !isToday && !isFuture
    }

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyDayView
                } else {
                    recordsListView
                }
            }
            .appScreenBackground()
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundStyle(AppColor.Text.secondary)
                }
            }
        }
        .appToastOverlay()
        .presentationDetents(records.isEmpty ? [.medium] : [.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Empty Day

    private var emptyDayView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            EmptyStateView(
                icon: "calendar.badge.plus",
                title: "이 날의 발견이 없어요",
                message: emptyDayMessage,
                actionTitle: canAddPastDiscovery ? "지난 발견 추가하기" : nil,
                action: canAddPastDiscovery ? {
                    dismiss()
                    onAddPastDiscovery()
                } : nil
            )

            Spacer()
        }
        .appScreenPadding()
    }

    // MARK: - Records List

    private var recordsListView: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.sm) {
                ForEach(records, id: \.id) { record in
                    if let collection = resolvedCollection(for: record) {
                        NavigationLink {
                            RecordDetailView(record: record, collection: collection)
                        } label: {
                            recordRow(record)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .appScreenPadding()
            .padding(.vertical, AppSpacing.md)
        }
    }

    private func recordRow(_ record: MODIRecord) -> some View {
        HStack(spacing: AppSpacing.md) {
            MODIRecordImage(record: record, contentMode: .fill)
                .frame(width: 64, height: 64)
                .modiRecordClipShape(for: record)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack(spacing: AppSpacing.xs) {
                    Text(record.conceptEmoji)
                    Text(record.conceptTitle)
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.Text.primary)
                }

                Text(record.collection?.title ?? record.conceptTitle)
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.Text.tertiary)
        }
        .appCardStyle()
    }

    // MARK: - Helpers

    private var emptyDayMessage: String {
        if isFuture {
            return "아직 오지 않은 날이에요"
        }
        if isToday {
            return "오늘의 미션으로 발견을 기록해 보세요"
        }
        return "그날 발견했던 순간을 나중에 기록할 수 있어요"
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 발견"
        return formatter.string(from: discoveryDay)
    }

    private func resolvedCollection(for record: MODIRecord) -> MODICollection? {
        if let collection = record.collection {
            return collection
        }
        return collectionRepository.collection(for: record.conceptId)
            ?? collectionRepository.ensureCollection(
                for: Concept.concept(for: record.conceptId) ?? Concept.mock
            )
    }
}

// MARK: - Preview

#Preview("With Records") {
    let (container, repository) = RecordPreviewData.makeRepository(withSampleData: true)
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()
    let records = repository.fetchRecords(on: .now)

    return DiscoveryDaySheet(
        date: .now,
        records: records,
        onAddPastDiscovery: {}
    )
    .environment(collectionRepository)
}

#Preview("Empty Past Day") {
    let (container, _) = RecordPreviewData.makeRepository()
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()

    return DiscoveryDaySheet(
        date: Calendar.current.date(byAdding: .day, value: -10, to: .now)!,
        records: [],
        onAddPastDiscovery: {}
    )
    .environment(collectionRepository)
}

#Preview("Empty Today") {
    let (container, _) = RecordPreviewData.makeRepository()
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()

    return DiscoveryDaySheet(
        date: .now,
        records: [],
        onAddPastDiscovery: {}
    )
    .environment(collectionRepository)
}
