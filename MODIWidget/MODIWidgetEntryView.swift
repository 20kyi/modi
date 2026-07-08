import SwiftUI
import WidgetKit

struct MODIWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    let entry: MODIWidgetEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                MODIWidgetMediumView(snapshot: entry.snapshot, colorScheme: colorScheme)
            default:
                MODIWidgetSmallView(snapshot: entry.snapshot, colorScheme: colorScheme)
            }
        }
        .widgetURL(MODIDeepLink.todayMissionURL)
    }
}

// MARK: - Small

private struct MODIWidgetSmallView: View {
    let snapshot: WidgetDailySnapshot
    let colorScheme: ColorScheme

    private let verticalSpacing: CGFloat = 12

    var body: some View {
        VStack(spacing: verticalSpacing) {
            Text("TODAY")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetColor.tertiaryText)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(snapshot.conceptEmoji)
                .font(.system(size: 44))

            Text(snapshot.conceptTitle)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetColor.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(spacing: 4) {
                Text("🔥")
                Text("\(snapshot.streakDays)일")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetColor.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .containerBackground(for: .widget) {
            WidgetColor.background(from: snapshot.themeColorHex, colorScheme: colorScheme)
        }
    }
}

// MARK: - Medium

private struct MODIWidgetMediumView: View {
    let snapshot: WidgetDailySnapshot
    let colorScheme: ColorScheme

    private let itemSpacing: CGFloat = 12

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: itemSpacing) {
                Text("오늘의 발견")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetColor.tertiaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    Text(snapshot.conceptEmoji)
                        .font(.system(size: 18))
                    Text(snapshot.conceptTitle)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(WidgetColor.primaryText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(snapshot.missionMessage)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(WidgetColor.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(WidgetColor.divider)
                    .frame(height: 1)

                HStack(spacing: 4) {
                    Text("🔥")
                    Text("\(snapshot.streakDays)일 연속 발견")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(WidgetColor.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            MODIWidgetPhotoView(snapshot: snapshot)
                .frame(width: 88, height: 88)
                .frame(maxHeight: .infinity, alignment: .center)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            WidgetColor.background(from: snapshot.themeColorHex, colorScheme: colorScheme)
        }
    }
}

// MARK: - Photo

private struct MODIWidgetPhotoView: View {
    let snapshot: WidgetDailySnapshot

    var body: some View {
        Group {
            if snapshot.hasPhoto, let data = WidgetDataStore.todayPhotoData(), let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(snapshot.conceptEmoji)
                    .font(.system(size: 44))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.22))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    MODIWidget()
} timeline: {
    MODIWidgetEntry(date: .now, snapshot: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    MODIWidget()
} timeline: {
    MODIWidgetEntry(date: .now, snapshot: .placeholder)
}

#Preview("Medium · Dark", as: .systemMedium) {
    MODIWidget()
} timeline: {
    MODIWidgetEntry(date: .now, snapshot: .placeholder)
}
