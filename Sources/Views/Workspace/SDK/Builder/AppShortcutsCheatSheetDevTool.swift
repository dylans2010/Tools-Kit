import SwiftUI

struct AppShortcutsCheatSheetDevTool: DevTool {
    let id = "app-shortcuts"
    let name = "App Shortcuts Cheat Sheet"
    let category: DevToolCategory = .utilities
    let icon = "command"
    let description = "Cheat sheet for standard macOS/iOS app shortcuts"

    func render() -> some View {
        List {
            Text("Cmd + Q: Quit")
            Text("Cmd + W: Close")
            Text("Cmd + N: New")
            Text("Cmd + ,: Settings")
        }
    }
}
