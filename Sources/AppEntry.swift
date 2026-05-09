import SwiftUI
import Appwrite
import CloudKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) {
            if notification.notificationType == .query {
                Task {
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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .registerOAuthHandler()
                .onAppear {
                    CloudKitManager.shared.requestPermissionsIfNeeded()
                    if UserDefaults.standard.bool(forKey: "CloudKitSyncEnabled") {
                        Task {
                            await CloudKitSubscriptionManager.shared.updateSubscriptions()
                            await CloudKitSyncEngine.shared.sync()
                        }
                    }
                }
        }
    }
}
