import SwiftUI

struct MethodTraceSimDevTool: DevTool {
    let id = "method-trace-sim"
    let name = "Method Trace Simulator"
    let category: DevToolCategory = .debugging
    let icon = "list.bullet.indent"
    let description = "Simulate and visualize method call stacks"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter root method") { input in
            let root = input.isEmpty ? "main" : input
            return "↳ \(root)\n  ↳ setup()\n    ↳ loadConfig()\n      ↳ fetchRemote()\n  ↳ runLoop()\n    ↳ updateUI()"
        }
    }
}
