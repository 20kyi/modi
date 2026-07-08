import WidgetKit

struct MODIWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MODIWidgetEntry {
        MODIWidgetEntry(date: .now, snapshot: .placeholder)
    }

    func snapshot(for configuration: MODIWidgetConfigurationIntent, in context: Context) async -> MODIWidgetEntry {
        MODIWidgetEntry(date: .now, snapshot: WidgetDataStore.loadOrPlaceholder())
    }

    func timeline(
        for configuration: MODIWidgetConfigurationIntent,
        in context: Context
    ) async -> Timeline<MODIWidgetEntry> {
        let snapshot = WidgetDataStore.loadOrPlaceholder()
        let entry = MODIWidgetEntry(date: .now, snapshot: snapshot)
        return Timeline(entries: [entry], policy: .after(nextMidnight()))
    }

    private func nextMidnight() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
        return calendar.startOfDay(for: tomorrow)
    }
}
