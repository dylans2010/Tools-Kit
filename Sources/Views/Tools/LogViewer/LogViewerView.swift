import SwiftUI

struct LogViewerView: View {
    @StateObject private var backend = LogViewerBackend()
    @State private var newLog = ""

    var body: some View {
        VStack {
            HStack {
                TextField("Add custom log...", text: $newLog)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Add") {
                    backend.addLog(newLog)
                    newLog = ""
                }
            }
            .padding()

            List(backend.logs, id: \.self) { log in
                Text(log)
                    .font(.system(.caption, design: .monospaced))
            }
            .listStyle(.plain)

            Button("Clear Logs", role: .destructive) {
                backend.clearLogs()
            }
            .padding()
        }
        .navigationTitle("Log Viewer")
        .onAppear {
            backend.addLog("Log session started.")
        }
    }
}

struct LogViewerTool: Tool {
    let name = "Log Viewer"
    let icon = "list.bullet.rectangle"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "View and debug application logs"
    let requiresAPI = false

    var view: AnyView {
        AnyView(LogViewerView())
    }
}
