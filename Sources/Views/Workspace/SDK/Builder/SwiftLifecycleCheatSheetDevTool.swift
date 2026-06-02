import SwiftUI

struct SwiftLifecycleCheatSheetDevTool: DevTool {
    let id = "swift-lifecycle"
    let name = "Swift Lifecycle Cheat Sheet"
    let category: DevToolCategory = .utilities
    let icon = "arrow.clockwise.circle"
    let description = "Cheat sheet for SwiftUI and UIViewController lifecycles"

    func render() -> some View {
        List {
            Section("SwiftUI") {
                Text(".onAppear()")
                Text(".onDisappear()")
                Text(".task()")
                Text(".onChange(of:)")
            }
            Section("UIViewController") {
                Text("viewDidLoad()")
                Text("viewWillAppear()")
                Text("viewDidAppear()")
                Text("viewWillDisappear()")
                Text("viewDidDisappear()")
            }
        }
    }
}
