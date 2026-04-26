import SwiftUI

struct WorkflowLogsView: View {
    let owner: String
    let repo: String
    let runID: Int

    @State private var logs = ""
    @State private var loading = false
    @State private var errorMessage: String?

    private let streamer = WorkflowLogStreamer()

    var body: some View {
        Group {
            if loading {
                ProgressView("Loading logs...")
            } else if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            } else {
                ScrollView {
                    Text(logs)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .font(.system(.footnote, design: .monospaced))
                }
            }
        }
        .navigationTitle("Run Logs")
        .task {
            loading = true
            defer { loading = false }

            do {
                logs = try await streamer.readLogText(owner: owner, repo: repo, runID: runID)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
