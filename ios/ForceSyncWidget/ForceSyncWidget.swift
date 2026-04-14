import WidgetKit
import SwiftUI

struct ForceSyncWidgetEntry: TimelineEntry {
    let date: Date
    let status: String
}

struct ForceSyncWidgetProvider: TimelineProvider {
    private let suite = UserDefaults(suiteName: "group.ForceSyncWidget")

    func placeholder(in context: Context) -> ForceSyncWidgetEntry {
        ForceSyncWidgetEntry(date: Date(), status: "idle")
    }

    func getSnapshot(in context: Context, completion: @escaping (ForceSyncWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ForceSyncWidgetEntry>) -> Void) {
        let timeline = Timeline(entries: [currentEntry()], policy: .atEnd)
        completion(timeline)
    }

    private func currentEntry() -> ForceSyncWidgetEntry {
        let status = suite?.string(forKey: "forceSyncWidget_status") ?? "idle"
        return ForceSyncWidgetEntry(date: Date(), status: status)
    }
}

struct ForceSyncWidgetEntryView: View {
    var entry: ForceSyncWidgetProvider.Entry
    let data = UserDefaults(suiteName: "group.ForceSyncWidget")

    @Environment(\.widgetFamily) var family

    private var assetName: String {
        switch entry.status {
        case "success": return "widget_check"
        case "error":   return "widget_error"
        default:        return "sync_now_small"
        }
    }

    private var tint: Color {
        switch entry.status {
        case "success": return Color(red: 0x85/255, green: 0xF4/255, blue: 0x8E/255)
        case "error":   return Color(red: 0xFD/255, green: 0xA4/255, blue: 0xAF/255)
        default:        return .white
        }
    }

    private var label: String {
        switch entry.status {
        case "syncing": return "SYNCING"
        case "success": return "SYNCED"
        case "error":   return "ERROR"
        default:        return "SYNC CHANGES"
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let repoIndex = data?.integer(forKey: "flutter.repoman_widgetSyncIndex") ?? -1
            let urlString = repoIndex >= 0
                ? "forcesyncwidget://click?homeWidget&index=\(repoIndex)"
                : "forcesyncwidget://click?homeWidget"

            if #available(iOSApplicationExtension 17, *) {
              Button(
                intent: BackgroundIntent(
                  url: URL(string: urlString),
                  appGroup: "group.ForceSyncWidget"
                )
              ) {
                  HStack(spacing: 16) {
                      Image(assetName)
                          .resizable()
                          .renderingMode(.template)
                          .scaledToFit()
                          .foregroundColor(tint)
                          .frame(maxWidth: 48, maxHeight: 48)

                      if geometry.size.width >= 140 {
                          Text(label)
                              .foregroundColor(tint)
                              .fontWeight(.bold)
                      }
                  }
                  .frame(maxWidth: .infinity, maxHeight: .infinity)
              }
              .buttonStyle(PlainButtonStyle())
              .widgetBackground(Color(red: 20/255, green: 20/255, blue: 20/255))
            } else {
              Button(
                  action: {}
              ) {
                  HStack(spacing: 16) {
                      Image(assetName)
                          .resizable()
                          .renderingMode(.template)
                          .scaledToFit()
                          .foregroundColor(tint)
                          .frame(maxWidth: 48, maxHeight: 48)

                      if geometry.size.width >= 140 {
                          Text(label)
                              .foregroundColor(tint)
                              .fontWeight(.bold)
                      }
                  }
                  .frame(maxWidth: .infinity, maxHeight: .infinity)
              }
              .widgetURL(URL(string: urlString))
              .buttonStyle(PlainButtonStyle())
              .widgetBackground(Color(red: 20/255, green: 20/255, blue: 20/255))
            }
        }
    }
}

struct ForceSyncWidget: Widget {
    let kind: String = "ForceSyncWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ForceSyncWidgetProvider()) { entry in
            ForceSyncWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Sync Now")
        .description("Widget to force sync changes")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

extension View {
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}
