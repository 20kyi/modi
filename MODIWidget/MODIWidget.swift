import SwiftUI
import WidgetKit

struct MODIWidget: Widget {
    let kind = AppGroupConstants.widgetKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: MODIWidgetConfigurationIntent.self,
            provider: MODIWidgetProvider()
        ) { entry in
            MODIWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("오늘의 MODI")
        .description("오늘의 미션과 연속 기록을 홈 화면에서 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
