import SwiftData
import SwiftUI

struct MonthlyMODIView: View {
    @Environment(RecordRepository.self) private var recordRepository
    @Environment(CollectionRepository.self) private var collectionRepository
    @Environment(MissionManager.self) private var missionManager
    @Environment(StreakManager.self) private var streakManager

    // Used only when showing "오늘의 발견 시작하기"
    @State private var showCreateFlow = false
    @State private var collectionStore = CollectionStore()

    private let monthDate: Date

    init(monthDate: Date = .now) {
        self.monthDate = monthDate
    }

    private var calendar: Calendar { .current }

    // MARK: - Month Interval (recordDate 기준)
    private var monthInterval: DateInterval {
        let components = calendar.dateComponents([.year, .month], from: monthDate)
        let start = calendar.date(from: components) ?? monthDate
        let startOfMonth = calendar.startOfDay(for: start)
        let end = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? startOfMonth
        return DateInterval(start: startOfMonth, end: end)
    }

    private var monthRecords: [MODIRecord] {
        let all = recordRepository.fetchAllRecords()
        return all
            .filter { record in
                let keyDate = record.recordDate ?? record.createdAt
                return keyDate >= monthInterval.start && keyDate < monthInterval.end
            }
            .sorted { $0.discoveryDate < $1.discoveryDate } // 날짜순(오래된 → 최신)
    }

    // MARK: - Header
    private var monthTitle: String {
        let year = calendar.component(.year, from: monthDate)
        let month = calendar.component(.month, from: monthDate)
        return "\(year)년 \(month)월의 MODI"
    }

    private var monthSubtitle: String {
        "이번 달에 \(monthRecords.count)개의 순간을 발견했어요."
    }

    private var gridColumnsCount: Int {
        let count = monthRecords.count
        switch count {
        case 0, 1: return max(1, min(1, count))
        case 2: return 2
        default: return 3
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(monthTitle)
                            .font(AppFont.title1)
                            .foregroundStyle(AppColor.Text.primary)

                        Text(monthSubtitle)
                            .font(AppFont.subheadline)
                            .foregroundStyle(AppColor.Text.secondary)
                    }

                    if monthRecords.isEmpty {
                        emptyState
                    } else {
                        photoGridSection
                        monthFinishCard
                    }
                }
                .appScreenPadding()
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxxl)
            }
            .appScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .fullScreenCover(isPresented: $showCreateFlow) {
                CreateView()
                    .environment(collectionStore)
            }
            .onAppear {
                collectionStore.configure(collectionRepository: collectionRepository)
            }

            // Navigation to record detail
            .navigationDestination(for: RecordNavigationValue.self) { navigationValue in
                if let record = monthRecords.first(where: { $0.id == navigationValue.id }),
                   let collection = record.collection ?? collectionRepository.collection(for: record.conceptId) {
                    RecordDetailView(record: record, collection: collection)
                } else {
                    EmptyView()
                }
            }
        }
    }

    // MARK: - Sections
    private var photoGridSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            let columns = Array(
                repeating: GridItem(.flexible(), spacing: AppSpacing.gridGutter),
                count: gridColumnsCount
            )

            LazyVGrid(columns: columns, spacing: AppSpacing.gridGutter) {
                ForEach(monthRecords, id: \.id) { record in
                    NavigationLink(value: RecordNavigationValue(id: record.id)) {
                        MODIRecordImage(record: record, contentMode: .fill)
                            .aspectRatio(1, contentMode: .fill)
                            .appPhotoStyle()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var monthFinishCard: some View {
        let total = monthRecords.count

        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("────────────────")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(AppColor.Text.quaternary)

            Text("\(monthInterval.start.yearMonthLabel)월의 작은 발견")
                .font(AppFont.title3)
                .foregroundStyle(AppColor.Text.primary)

            Text("\(total)개의 순간을 기록했습니다.")
                .font(AppFont.subheadline)
                .foregroundStyle(AppColor.Text.secondary)

            Text("────────────────")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(AppColor.Text.quaternary)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppColor.Background.secondary,
            in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(AppColor.Border.subtle, lineWidth: 0.75)
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("🌱")
                .font(.system(size: 56))
                .accessibilityLabel("Empty State")

            Text("아직 이번 달의 발견이 없어요.")
                .font(AppFont.title2)
                .foregroundStyle(AppColor.Text.primary)
                .multilineTextAlignment(.center)

            Text("오늘의 미션부터 시작해보세요.")
                .font(AppFont.footnote)
                .foregroundStyle(AppColor.Text.secondary)
                .multilineTextAlignment(.center)

            Button {
                showCreateFlow = true
            } label: {
                Text("오늘의 발견 시작하기")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.massive)
    }

}

private extension Date {
    /// Example: for 2026-07-08 => "7" (month number without trailing "월")
    var yearMonthLabel: Int {
        Calendar.current.component(.month, from: self)
    }
}

#Preview("Month MODI · Light") {
    let (container, repository) = RecordPreviewData.makeRepository(withSampleData: true)
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()

    return MonthlyMODIView()
        .modelContainer(container)
        .environment(repository)
        .environment(collectionRepository)
        .environment(MissionManager.mock)
        .environment(StreakManager.mock)
        .preferredColorScheme(.light)
}

#Preview("Month MODI · Dark") {
    let (container, repository) = RecordPreviewData.makeRepository(withSampleData: true)
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    collectionRepository.bootstrap()

    return MonthlyMODIView()
        .modelContainer(container)
        .environment(repository)
        .environment(collectionRepository)
        .environment(MissionManager.mock)
        .environment(StreakManager.mock)
        .preferredColorScheme(.dark)
}

