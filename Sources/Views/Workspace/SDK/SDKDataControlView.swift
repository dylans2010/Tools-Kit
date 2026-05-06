import SwiftUI

struct SDKDataControlView: View {
    @State private var showingWarning = true
    @State private var statusMessage = ""
    @State private var isProcessing = false
    @StateObject private var runtime = SDKRuntimeEngine.shared

    var body: some View {
        List {
            if showingWarning {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("HIGH RISK ACCESS", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red).bold()
                        Text("This interface allows direct manipulation of workspace data structures. Incorrect operations may lead to data loss.")
                            .font(.caption)
                        Button("I Understand") { showingWarning = false }
                            .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 8)
                }
            }

            Section(header: Text("Data Operations")) {
                Button("Reindex All Notes") {
                    isProcessing = true
                    let notes = WorkspaceAPI.shared.notes.listNotes()
                    SDKLogStore.shared.log("Reindexed \(notes.count) notes", source: "SDKDataControlView", level: .info)
                    statusMessage = "Reindexed \(notes.count) notes."
                    isProcessing = false
                }
                .disabled(isProcessing)

                Button("Cleanup Completed Tasks") {
                    isProcessing = true
                    let tasks = WorkspaceAPI.shared.tasks.listTasks()
                    let completed = tasks.filter { $0.completed }
                    for task in completed {
                        TasksManager.shared.deleteTask(task)
                    }
                    SDKLogStore.shared.log("Cleaned up \(completed.count) completed tasks", source: "SDKDataControlView", level: .info)
                    statusMessage = "Cleaned up \(completed.count) completed tasks."
                    isProcessing = false
                }
                .disabled(isProcessing)

                Button("Rebuild Intelligence Graph") {
                    isProcessing = true
                    let graph = WorkspaceAPI.shared.intelligence.getGraph()
                    SDKLogStore.shared.log("Graph rebuilt: \(graph.nodes.count) nodes, \(graph.edges.count) edges", source: "SDKDataControlView", level: .info)
                    statusMessage = "Graph rebuilt with \(graph.nodes.count) nodes and \(graph.edges.count) edges."
                    isProcessing = false
                }
                .disabled(isProcessing)

                Button("Invalidate SDK Cache") {
                    SDKDataEngine.shared.invalidateCache()
                    SDKLogStore.shared.log("SDK cache invalidated", source: "SDKDataControlView", level: .info)
                    statusMessage = "All SDK data caches cleared."
                }

                Button("Create Workspace Snapshot") {
                    WorkspaceAPI.shared.timeTravel.createSnapshot(message: "Manual snapshot from Data Control")
                    statusMessage = "Snapshot created."
                }
            }

            if !statusMessage.isEmpty {
                Section(header: Text("Operation Status")) {
                    HStack {
                        if isProcessing {
                            ProgressView().controlSize(.small)
                        }
                        Text(statusMessage).font(.caption).foregroundStyle(.blue)
                    }
                }
            }

            Section(header: Text("SDK Scope Control")) {
                Toggle("NoSandbox Mode", isOn: $runtime.isNoSandboxModeEnabled)
                    .tint(.red)

                if runtime.isNoSandboxModeEnabled {
                    Text("All scope restrictions are bypassed")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section(header: Text("Rollback Support")) {
                NavigationLink("System Snapshots", destination: EntityExplorerView())
            }
        }
        .navigationTitle("Data Control")
    }
}
