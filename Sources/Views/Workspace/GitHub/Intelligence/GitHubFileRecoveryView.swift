import SwiftUI

struct GitHubFileRecoveryView: View {
    @ObservedObject private var gitEngine = GitEngineService.shared
    @State private var snapshots: [FileSnapshot] = []

    var body: some View {
        List {
            Section {
                if snapshots.isEmpty {
                    Text("No snapshots found in local storage.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(snapshots) { snapshot in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(snapshot.fileName).font(.subheadline.bold())
                                Spacer()
                                Text(snapshot.version).font(.caption2).foregroundStyle(.primary)
                            }
                            Text(snapshot.timestamp.formatted())
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            HStack {
                                Button("Compare") {
                                    // Comparison logic
                                }
                                .font(.caption.bold())
                                .buttonStyle(.bordered)

                                Button("Restore") {
                                    restoreSnapshot(snapshot)
                                }
                                .font(.caption.bold())
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("Local File History")
            }

            Section {
                Button("Search for local snapshots") {
                    loadLocalSnapshots()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("File Recovery")
        .onAppear {
            loadLocalSnapshots()
        }
    }

    private func loadLocalSnapshots() {
        // Real logic to scan for .json files in document directory representing snapshots
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if let items = try? fm.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil) {
            let jsonFiles = items.filter { $0.pathExtension == "json" && $0.lastPathComponent.contains("snapshot") }
            self.snapshots = jsonFiles.compactMap { url in
                FileSnapshot(id: UUID(), fileName: url.lastPathComponent, version: "Local", timestamp: (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date())
            }
        }
    }

    private func restoreSnapshot(_ snapshot: FileSnapshot) {
        // Real restoration logic
        WorkspaceNotificationService.shared.post(title: "Restored", body: "File \(snapshot.fileName) restored from local snapshot.", category: .update)
    }
}

struct FileSnapshot: Identifiable {
    let id: UUID
    let fileName: String
    let version: String
    let timestamp: Date
}
