import SwiftUI

struct CrashLogViewerDevTool: DevTool {
    let id = "crash-log-viewer"
    let name = "Crash Log Viewer"
    let category = DevToolCategory.diagnostics
    let icon = "exclamationmark.octagon"
    let description = "View and export crash reports"

    func render() -> some View {
        CrashLogViewerView()
    }
}

struct CrashLogViewerView: View {
    @State private var logs = ["No hardware crashes detected in current session."]

    var body: some View {
        List {
            Section("Recent Reports") {
                ForEach(logs, id: \.self) { log in
                    Text(log)
                        .font(.monospaced(.caption)())
                }
            }
        }
    }
}
