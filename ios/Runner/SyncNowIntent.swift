import AppIntents
import Foundation
import home_widget

@available(iOS 17, *)
struct SyncNowIntent: AppIntent {
    static var title: LocalizedStringResource = "Sync Now"
    static var description: IntentDescription? = IntentDescription(
        "Synchronize the currently selected repository")
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = true

    func perform() async throws -> some IntentResult {
        let syncUrl = URL(string: "gitsync://sync-now")!

        await HomeWidgetBackgroundWorker.run(url: syncUrl, appGroup: "group.ForceSyncWidget")

        return .result()
    }
}
