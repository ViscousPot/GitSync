import WidgetKit
import SwiftUI

struct ForceSyncWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ForceSyncWidgetEntry {
        ForceSyncWidgetEntry(date: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ForceSyncWidgetEntry) -> Void) {
        let entry = ForceSyncWidgetEntry(date: Date())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ForceSyncWidgetEntry>) -> Void) {
        let entries = [ForceSyncWidgetEntry(date: Date())]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct ForceSyncWidgetEntry: TimelineEntry {
    let date: Date
}

struct ForceSyncWidgetEntryView: View {
    var entry: ForceSyncWidgetProvider.Entry
    let data = UserDefaults.init(suiteName:"group.ForceSyncWidget")

    @Environment(\.widgetFamily) var family

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
                      Image("sync_now_small")
                          .resizable()
                          .scaledToFit()
                          .foregroundColor(.white)
                          .frame(maxWidth: 48, maxHeight: 48)

                      if geometry.size.width >= 140 {
                          Text("SYNC CHANGES")
                              .foregroundColor(.white)
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
                      Image("sync_now_small")
                          .resizable()
                          .scaledToFit()
                          .foregroundColor(.white)
                          .frame(maxWidth: 48, maxHeight: 48)

                      if geometry.size.width >= 140 {
                          Text("SYNC CHANGES")
                              .foregroundColor(.white)
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
