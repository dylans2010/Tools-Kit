import SwiftUI

struct EnvVarInspectorDevTool: DevTool {
    let id = "env-var-inspector"
    let name = "Environment Variable Inspector"
    let category: DevToolCategory = .diagnostics
    let icon = "terminal"
    let description = "Inspect current process environment variables"

    func render() -> some View {
        List {
            ForEach(ProcessInfo.processInfo.environment.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                VStack(alignment: .leading) {
                    Text(key).font(.caption.bold())
                    Text(value).font(.system(.caption2, design: .monospaced)).foregroundStyle(.secondary)
                }
            }
        }
    }
}
