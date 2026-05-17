import AppIntents
import Foundation

@available(iOS 17, *)
struct SyncNowIntent: AppIntent {
    static var title: LocalizedStringResource = "Sync Now"
    static var description: IntentDescription? = IntentDescription(
        "Synchronize the currently selected repository")
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = true

    func perform() async throws -> some IntentResult {
        let backgroundIntent = BackgroundIntent(
            url: URL(string: "gitsync://sync-now?homeWidget"),
            appGroup: "group.ForceSyncWidget"
        )
        try await backgroundIntent.perform()

        return .result()
    }
}

@available(iOS 17, *)
@available(iOSApplicationExtension, unavailable)
extension SyncNowIntent: ForegroundContinuableIntent {}
