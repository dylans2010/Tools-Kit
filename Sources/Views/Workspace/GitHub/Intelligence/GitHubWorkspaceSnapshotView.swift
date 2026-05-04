import SwiftUI

struct GitHubWorkspaceSnapshotView: View {
    @State private var snapshots: [WorkspaceSnapshot] = [
        WorkspaceSnapshot(id: UUID(), name: "Pre-Refactor Snapshot", branch: "main", timestamp: Date()),
        WorkspaceSnapshot(id: UUID(), name: "Stable Release 1.1.0", branch: "main", timestamp: Date().addingTimeInterval(-604800))
    ]

    var body: some View {
        List {
            Section("Repository Snapshots") {
                ForEach(snapshots) { snapshot in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(snapshot.name).font(.subheadline.bold())
                            Spacer()
                            Text(snapshot.branch).font(.caption2).foregroundStyle(.secondary)
                        }
                        Text(snapshot.timestamp.formatted())
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        HStack {
                            Button("Diff") { /* Diff logic */ }
                            Button("Restore") { /* Restore logic */ }
                        }
                        .font(.caption.bold())
                        .buttonStyle(.bordered)
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                Button("Capture Full State Snapshot") {
                    snapshots.insert(WorkspaceSnapshot(id: UUID(), name: "Manual Snapshot", branch: "main", timestamp: Date()), at: 0)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Workspace Snapshots")
    }
}

struct WorkspaceSnapshot: Identifiable {
    let id: UUID
    let name: String
    let branch: String
    let timestamp: Date
}
