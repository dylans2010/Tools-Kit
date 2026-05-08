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
                    SDKModernCard(padding: 12, content: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "exclamationmark.shield.fill").foregroundStyle(.sdkError)
                                Text("High Risk Access").font(.subheadline.bold())
                            }
                            Text("This interface allows direct manipulation of workspace data structures. Incorrect operations may lead to data loss.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Button {
                                showingWarning = false
                            } label: {
                                Text("Acknowledge & Continue")
                                    .font(.caption.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.sdkError.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                    .foregroundStyle(.sdkError)
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            Section {
                Button("Reindex All Notes") {
                    isProcessing = true
                    let notes = WorkspaceAPI.shared.notes.listNotes()
                    SDKLogStore.shared.log("Reindexed \(notes.count) Notes", source: "SDKDataControlView", level: .info)
                    statusMessage = "Reindexed \(notes.count) Notes."
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
                Section {
                    SDKNotificationBanner(message: statusMessage, type: isProcessing ? .info : .success)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } header: {
                    SDKSectionHeader("Operation Status", subtitle: "Live execution feedback", alignment: .leading)
                }
            }

            Section {
                Toggle(isOn: $runtime.isNoSandboxModeEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No-Sandbox Mode").font(.subheadline.bold())
                            Text("Bypass all execution restrictions").font(.caption2).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "shield.slash.fill").foregroundStyle(.sdkError)
                    }
                }
                .tint(.sdkError)

                if runtime.isNoSandboxModeEnabled {
                    SDKStatusPill("Restricted Mode Bypassed", color: .sdkError, isCapsule: false)
                        .padding(.vertical, 4)
                }
            } header: {
                SDKSectionHeader("Scope Control", subtitle: "Kernel environment flags", systemImage: "slider.horizontal.3")
            }

            Section {
                NavigationLink(destination: EntityExplorerView()) {
                    Label("System Snapshots", systemImage: "clock.arrow.circlepath")
                }
            } header: {
                SDKSectionHeader("Rollback Support", subtitle: "Time travel and state recovery", systemImage: "arrow.uturn.backward")
            }
        }
        .navigationTitle("Data Control")
    }
}
