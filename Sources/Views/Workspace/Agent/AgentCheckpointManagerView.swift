import SwiftUI

struct AgentCheckpointManagerView: View {
    @ObservedObject var state: AgentSessionState
    @State private var isRestoring = false
    @State private var restoreError: String?
    @State private var isCreating = false

    var body: some View {
        List {
            Section {
                Button(action: createCheckpoint) {
                    if isCreating {
                        HStack {
                            ProgressView().padding(.trailing, 8)
                            Text("Creating Checkpoint...")
                        }
                    } else {
                        Label("Create New Checkpoint", systemImage: "plus.circle.fill")
                    }
                }
                .disabled(isCreating || isRestoring)
            }

            if state.checkpoints.isEmpty && !isCreating {
                ContentUnavailableView(
                    "No Checkpoints",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Checkpoints allow you to save and restore the workspace state.")
                )
            } else {
                ForEach(state.checkpoints.sorted(by: { $0.timestamp > $1.timestamp })) { checkpoint in
                    CheckpointRow(checkpoint: checkpoint, onRestore: {
                        restore(checkpoint)
                    })
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Checkpoints")
        .overlay {
            if isRestoring {
                ProgressView("Restoring Checkpoint...")
                    .padding()
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 10)
            }
        }
        .alert("Restore Failed", isPresented: Binding(get: { restoreError != nil }, set: { if !$0 { restoreError = nil } })) {
            Button("OK") { restoreError = nil }
        } message: {
            if let error = restoreError {
                Text(error)
            }
        }
    }

    private func createCheckpoint() {
        isCreating = true
        Task {
            do {
                let context = SystemToolContext(workspaceId: state.workspaceId, sessionId: state.id, timestamp: ISO8601DateFormatter().string(from: Date()))
                _ = try await AgentSystemTools.shared.execute(name: "create_checkpoint", input: ["description": "User created checkpoint"], context: context)
                await MainActor.run { isCreating = false }
            } catch {
                await MainActor.run {
                    isCreating = false
                    restoreError = error.localizedDescription
                }
            }
        }
    }

    private func restore(_ checkpoint: AgentCheckpoint) {
        isRestoring = true
        Task {
            do {
                let context = SystemToolContext(workspaceId: state.workspaceId, sessionId: state.id, timestamp: ISO8601DateFormatter().string(from: Date()))
                _ = try await AgentSystemTools.shared.execute(name: "restore_checkpoint", input: ["checkpoint_id": checkpoint.id], context: context)

                await MainActor.run {
                    isRestoring = false
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    restoreError = error.localizedDescription
                }
            }
        }
    }
}

struct CheckpointRow: View {
    let checkpoint: AgentCheckpoint
    let onRestore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(checkpoint.description)
                        .font(.headline)
                    Text(checkpoint.timestamp, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(checkpoint.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: onRestore) {
                    Label("Restore", systemImage: "arrow.uturn.backward")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            }

            if let branch = checkpoint.branchName {
                HStack {
                    Image(systemName: "arrow.triangle.pull")
                    Text(branch)
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
    }
}
