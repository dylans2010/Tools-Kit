import SwiftUI
import Appwrite

@main
struct ToolsKitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .registerOAuthHandler()
                .onOpenURL { url in
                    _ = GmailAuthManager.shared.receiveRedirectURL(url)
                }
        }
    }
}
