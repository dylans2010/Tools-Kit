import SwiftUI

struct MemoryLeakGuideDevTool: DevTool {
    let id = "memory-leak-guide"
    let name = "Memory Leak Guide"
    let category: DevToolCategory = .diagnostics
    let icon = "bandage"
    let description = "Diagnostic guide for finding memory leaks in Swift"

    func render() -> some View {
        List {
            Section("Common Causes") {
                Text("• Strong reference cycles in closures")
                Text("• Delegate properties not marked 'weak'")
                Text("• Notification Center observers not removed")
                Text("• Timer instances not invalidated")
            }
            Section("Tools to Use") {
                Text("• Xcode Memory Graph Debugger")
                Text("• Instruments (Leaks/Allocations)")
                Text("• deinit { print(\"deinit\") } debugging")
            }
        }
    }
}
