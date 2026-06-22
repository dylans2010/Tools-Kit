import SwiftUI
import Appwrite

@main
struct ToolsKitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .registerOAuthHandler()
                .onOpenURL { url in
                    if url.scheme == "toolskit" && url.host == "lm-callback" {
                        LMLinkAuthManager.shared.handleCallback(url: url)
                    }
                }
        }
    }
}
