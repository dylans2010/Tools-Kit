/*
 REDESIGN SUMMARY:
 - Transitioned to standard Form layout for system-level data operations.
 - Standardized high-risk warning using a prominent Section with semantic red coloring.
 - Replaced manual SDKModernCard and button styles with native Form components.
 - Standardized operation feedback using a status section with semantic colors.
 - strictly preserved all WorkspaceAPI, SDKLogStore, and SDKRuntimeEngine integration logic.
 - Improved visual hierarchy for 'No-Sandbox' mode using a native Toggle with descriptive text.
 - Replaced manual navigation links with standard List Section links.
 */

import SwiftUI

struct SDKDataControlView: View {
    @State private var showingWarning = true
    @State private var statusMessage = ""
    @State private var isProcessing = false
    @StateObject private var runtime = SDKRuntimeEngine.shared

    var body: some View {
        Form {
            if showingWarning {
                warningSection
            }

            Section {
                Button("Reindex All Notes") { runMaintenanceTask("Reindexed all notes") { WorkspaceAPI.shared.notes.listNotes() } }
                Button("Cleanup Completed Tasks") { cleanupTasks() }
                Button("Rebuild Intelligence Graph") { runMaintenanceTask("Intelligence graph rebuilt") { WorkspaceAPI.shared.intelligence.getGraph() } }
                Button("Invalidate SDK Cache") { SDKDataEngine.shared.invalidateCache(); statusMessage = "Cache cleared" }
                Button("Create Workspace Snapshot") { WorkspaceAPI.shared.timeTravel.createSnapshot(message: "Manual snapshot"); statusMessage = "Snapshot created" }
            } header: {
                Text("System Maintenance")
            } footer: {
                Text("Direct manipulation of data structures can lead to permanent loss.")
            }

            if !statusMessage.isEmpty {
                Section("Status") {
                    Text(statusMessage)
                        .font(.subheadline.bold())
                        .foregroundStyle(isProcessing ? .secondary : .green)
                }
            }

            Section("Security Control") {
                Toggle(isOn: $runtime.isNoSandboxModeEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No-Sandbox Mode")
                            Text("Bypass execution restrictions")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "shield.slash")
                            .foregroundStyle(runtime.isNoSandboxModeEnabled ? .red : .secondary)
                    }
                }
                .tint(.red)
            }

            Section("State Recovery") {
                NavigationLink {
                    EntityExplorerView()
                } label: {
                    Label("System Snapshots", systemImage: "clock.arrow.circlepath")
                }
            }
        }
        .navigationTitle("Data Control")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var warningSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("High Risk Access", systemImage: "exclamationmark.shield.fill")
                    .font(.headline)
                    .foregroundStyle(.red)
                Text("This interface allows direct manipulation of workspace data. Incorrect operations may lead to data corruption.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Acknowledge & Continue") { showingWarning = false }
                    .buttonStyle(.bordered)
                    .tint(.red)
            }
            .padding(.vertical, 8)
        }
    }

    private func runMaintenanceTask(_ label: String, action: () -> Void) {
        isProcessing = true
        action()
        statusMessage = label
        isProcessing = false
        SDKLogStore.shared.log(label, source: "SDKDataControlView", level: .info)
    }

    private func cleanupTasks() {
        isProcessing = true
        let tasks = WorkspaceAPI.shared.tasks.listTasks()
        let completed = tasks.filter { $0.completed }
        for task in completed { TasksManager.shared.deleteTask(task) }
        statusMessage = "Cleaned up \(completed.count) tasks"
        isProcessing = false
        SDKLogStore.shared.log(statusMessage, source: "SDKDataControlView", level: .info)
    }
}
