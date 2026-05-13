import SwiftUI

struct WorkflowLogsView: View {
    let owner: String
    let repo: String
    let runID: Int

    @State private var logs = ""
    @State private var loading = false
    @State private var errorMessage: String?
    @State private var failureReasons: [String] = []
    @State private var artifacts: [WorkflowArtifact] = []

    private let streamer = WorkflowLogStreamer()
    private let client = GitHubActionsClient()

    var body: some View {
        List {
            if loading {
                ProgressView("Loading logs...")
            } else if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            } else {
                Section {
                    if failureReasons.isEmpty {
                        Text("No obvious failures detected.")
                    } else {
                        ForEach(failureReasons, id: \.self) { reason in
                            Text(reason).font(.caption)
                        }
                    }
                } header: {
                    Text("Failure Detection")
                }

                Section {
                    if artifacts.isEmpty {
                        Text("No artifacts found.")
                    } else {
                        ForEach(artifacts) { artifact in
                            VStack(alignment: .leading) {
                                Text(artifact.name)
                                Text("\(artifact.sizeInBytes) bytes").font(.caption2)
                            }
                        }
                    }
                } header: {
                    Text("Artifacts")
                }

                Section {
                    ScrollView {
                        Text(logs)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(.footnote, design: .monospaced))
                    }
                    .frame(minHeight: 260)
                } header: {
                    Text("Logs")
                }
            }
        }
        .navigationTitle("Run Logs")
        .task {
            loading = true
            defer { loading = false }

            do {
                async let logText = streamer.readLogText(owner: owner, repo: repo, runID: runID)
                async let fetchedArtifacts = client.listArtifacts(owner: owner, repo: repo, runID: runID)
                logs = try await logText
                artifacts = try await fetchedArtifacts
                failureReasons = await streamer.extractFailureReasons(from: logs)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
