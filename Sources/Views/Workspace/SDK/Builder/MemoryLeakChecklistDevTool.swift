import SwiftUI

struct MemoryLeakChecklistDevTool: DevTool {
    let id = "memory-leak-checklist"
    let name = "Memory Leak Checklist"
    let category: DevToolCategory = .diagnostics
    let icon = "exclamationmark.shield"
    let description = "Checklist for common memory leak causes in Swift"

    func render() -> some View {
        List {
            Toggle("Strong Reference Cycles in Closures", isOn: .constant(false))
            Toggle("Delegate not marked as 'weak'", isOn: .constant(false))
            Toggle("Unowned/Weak self usage in escaping closures", isOn: .constant(false))
            Toggle("NotificationCenter observers not removed", isOn: .constant(false))
            Toggle("Timer not invalidated", isOn: .constant(false))
        }
    }
}
