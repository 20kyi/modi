import SwiftUI

// MARK: - DiscoveryCalendarView

struct DiscoveryCalendarView: View {

    let recordedDayEmojis: [String: String]
    @State private var displayedMonth: Date

    private let calendar = Calendar.current
    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

    init(recordedDayEmojis: [String: String], referenceMonth: Date = .now) {
        self.recordedDayEmojis = recordedDayEmojis
        let components = Calendar.current.dateComponents([.year, .month], from: referenceMonth)
        _displayedMonth = State(
            initialValue: Calendar.current.date(from: components) ?? referenceMonth
        )
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            monthHeader
            weekdayHeader
            dayGrid
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.Text.secondary)
                    .frame(width: AppSpacing.minTouchTarget, height: AppSpacing.minTouchTarget)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(monthTitle)
                .font(AppFont.headline)
                .foregroundStyle(AppColor.Text.primary)

            Spacer()

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(canGoForward ? AppColor.Text.secondary : AppColor.Text.tertiary)
                    .frame(width: AppSpacing.minTouchTarget, height: AppSpacing.minTouchTarget)
            }
            .buttonStyle(.plain)
            .disabled(!canGoForward)
        }
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppSpacing.xs) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(AppFont.caption2)
                    .foregroundStyle(AppColor.Text.tertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Day Grid

    private var dayGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppSpacing.sm) {
            ForEach(monthDays, id: \.self) { day in
                if let day {
                    dayCell(for: day)
                } else {
                    Color.clear
                        .frame(height: 36)
                }
            }
        }
    }

    private func dayCell(for date: Date) -> some View {
        let dayKey = DailyMission.dayKey(for: date)
        let dayEmoji = recordedDayEmojis[dayKey]
        let hasRecord = dayEmoji != nil
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > calendar.startOfDay(for: .now)

        return VStack(spacing: AppSpacing.xxs) {
            if let dayEmoji {
                Text(dayEmoji)
                    .font(.system(size: 18))
            } else {
                Text("\(calendar.component(.day, from: date))")
                    .font(isToday ? AppFont.subheadline.weight(.semibold) : AppFont.subheadline)
                    .foregroundStyle(dayNumberColor(isToday: isToday, isFuture: isFuture))
            }

            Circle()
                .fill(hasRecord ? AppColor.Accent.primary : Color.clear)
                .frame(width: 6, height: 6)
                .overlay {
                    if !hasRecord, !isFuture {
                        Circle()
                            .strokeBorder(AppColor.Border.subtle, lineWidth: 1)
                            .frame(width: 6, height: 6)
                    }
                }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .background {
            if isToday {
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .fill(AppColor.Accent.soft.opacity(0.5))
            }
        }
    }

    // MARK: - Helpers

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: displayedMonth)
    }

    private var canGoForward: Bool {
        let currentComponents = calendar.dateComponents([.year, .month], from: .now)
        let displayedComponents = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let currentYear = currentComponents.year,
              let currentMonth = currentComponents.month,
              let displayedYear = displayedComponents.year,
              let displayedMonthValue = displayedComponents.month else {
            return false
        }
        return displayedYear < currentYear
            || (displayedYear == currentYear && displayedMonthValue < currentMonth)
    }

    private var monthDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }

        let leadingEmpty = firstWeekday - 1
        var days: [Date?] = Array(repeating: nil, count: leadingEmpty)

        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return days
    }

    private func shiftMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        displayedMonth = newMonth
    }

    private func dayNumberColor(isToday: Bool, isFuture: Bool) -> Color {
        if isFuture { return AppColor.Text.tertiary }
        if isToday { return AppColor.Accent.primary }
        return AppColor.Text.secondary
    }
}

// MARK: - Preview

#Preview("With Records") {
    DiscoveryCalendarView(
        recordedDayEmojis: Dictionary(
            uniqueKeysWithValues: (0..<12).compactMap { offset -> (String, String)? in
                guard let date = Calendar.current.date(byAdding: .day, value: -offset, to: .now) else {
                    return nil
                }
                return (DailyMission.dayKey(for: date), "📸")
            }
        )
    )
    .appCardStyle()
    .appScreenPadding()
    .appScreenBackground()
}

#Preview("Empty") {
    DiscoveryCalendarView(recordedDayEmojis: [:])
        .appCardStyle()
        .appScreenPadding()
        .appScreenBackground()
}
