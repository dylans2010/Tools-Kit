import SwiftUI

struct GitHubWorkspaceSnapshotView: View {
    @ObservedObject private var gitEngine = GitEngineService.shared
    @State private var snapshots: [WorkspaceSnapshot] = []

    var body: some View {
        List {
            Section("Repository Snapshots") {
                if snapshots.isEmpty {
                    Text("No snapshots found in local storage.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
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
            }

            Section {
                Button("Capture Full State Snapshot") {
                    captureSnapshot()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Workspace Snapshots")
        .onAppear {
            loadSnapshots()
        }
    }

    private func loadSnapshots() {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if let items = try? fm.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil) {
            let snapshotFiles = items.filter { $0.lastPathComponent.contains("repo_snapshot_") }
            self.snapshots = snapshotFiles.compactMap { url in
                WorkspaceSnapshot(id: UUID(), name: "Automatic Backup", branch: "main", timestamp: (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date())
            }
        }
    }

    private func captureSnapshot() {
        let filename = "repo_snapshot_\(Int(Date().timeIntervalSince1970)).json"
        let data = (try? JSONEncoder().encode(gitEngine.stagedChanges)) ?? Data()
        try? WorkspacePersistence.shared.save(data, to: filename)
        loadSnapshots()
    }
}

