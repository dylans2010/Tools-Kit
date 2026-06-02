import SwiftUI

struct SwiftConcurrencyCheatSheetDevTool: DevTool {
    let id = "swift-concurrency"
    let name = "Swift Concurrency Cheat Sheet"
    let category: DevToolCategory = .utilities
    let icon = "timer"
    let description = "Cheat sheet for async/await and structured concurrency"

    func render() -> some View {
        List {
            Text("async / await")
            Text("Task { ... }")
            Text("Task.detached { ... }")
            Text("async let result = ...")
            Text("withTaskGroup(of: T.self) { ... }")
            Text("@MainActor")
        }
    }
}
