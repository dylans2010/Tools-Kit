import SwiftUI
import Appwrite

@main
struct ToolsKitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .registerOAuthHandler()
                .onOpenURL { url in
                    AppDeepLinkRouter.shared.handle(url)
                }
                .task {
                    await LMLinkAuthManager.shared.restoreSession()
                }
        }
    }
}
