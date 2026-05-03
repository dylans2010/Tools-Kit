import SwiftUI
import Appwrite

@main
struct ToolsKitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .registerOAuthHandler()
                .onAppear {
                    #if DEBUG
                    ValidationTests.runAll()
                    #endif
                }
        }
    }
}
