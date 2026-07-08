import AppIntents
import WidgetKit

struct MODIWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "MODI"
    static var description = IntentDescription("오늘의 미션을 홈 화면에서 확인하세요.")
}
