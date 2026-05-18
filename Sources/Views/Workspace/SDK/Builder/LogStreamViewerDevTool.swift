import SwiftUI

struct LogStreamViewerDevTool: DevTool {
    let id = "log-stream-viewer"
    let name = "Log Stream Viewer"
    let category = DevToolCategory.debugging
    let icon = "terminal"
    let description = "Real-time application log stream"

    func render() -> some View {
        LogStreamView()
    }
}

struct LogStreamView: View {
    @State private var logs: [String] = ["App started", "SDK initialized", "Waiting for user action..."]

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(logs, id: \.self) { log in
                        Text(log)
                            .font(.monospaced(.caption)())
                            .padding(.vertical, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .background(Color.black)
            .foregroundStyle(.green)

            HStack {
                Button("Simulate Log") {
                    logs.append("User tapped button at \(Date())")
                }
                Spacer()
                Button("Clear") { logs = [] }
            }
            .padding()
        }
    }
}
