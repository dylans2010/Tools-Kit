import SwiftUI
import Appwrite
import CloudKit
import OSLog

class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = Logger(subsystem: "com.toolskit.app", category: "AppDelegate")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) {
            if notification.notificationType == .query {
                Task {
                    let isCloudKitAvailable = await CloudKitManager.shared.isCloudKitAvailable()
                    guard isCloudKitAvailable else {
                        self.logger.info("Skipping push-triggered CloudKit sync because iCloud is unavailable.")
                        completionHandler(.noData)
                        return
                    }
                    await CloudKitSyncEngine.shared.sync()
                    completionHandler(.newData)
                }
                return
            }
        }
        completionHandler(.noData)
    }
}

@main
struct ToolsKitApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let logger = Logger(subsystem: "com.toolskit.app", category: "ToolsKitApp")

    var body: some Scene {
        WindowGroup {
            ContentView()
                .registerOAuthHandler()
                .onAppear {
                    Task {
                        let isCloudKitAvailable = await CloudKitManager.shared.isCloudKitAvailable()
                        guard isCloudKitAvailable else {
                            logger.info("CloudKit unavailable at launch; startup sync/subscription setup skipped.")
                            return
                        }

                        CloudKitManager.shared.requestPermissionsIfNeeded()
                        if UserDefaults.standard.bool(forKey: "CloudKitSyncEnabled") {
                            await CloudKitSubscriptionManager.shared.updateSubscriptions()
                            await CloudKitSyncEngine.shared.sync()
                        }
                    }
                }
        }
    }
}
