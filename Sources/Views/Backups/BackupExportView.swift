import SwiftUI

struct BackupExportView: View {
    let backup: BackupMetadata?
    @Environment(\.dismiss) private var dismiss
    @State private var manager = BackupManager.shared

    var body: some View {
        NavigationStack {
            List {
                if let backup = backup {
                    Section("Selected Backup") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(backup.name).bold()
                            Text(backup.id.uuidString).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                        }
                    }

                    Section {
                        Button {
                            shareBackup(backup)
                        } label: {
                            Label("Share .zip File", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            saveToFiles(backup)
                        } label: {
                            Label("Save to Files App", systemImage: "folder.badge.plus")
                        }
                    }
                } else {
                    Section("All Backups") {
                        ForEach(manager.availableBackups) { b in
                            Button {
                                shareBackup(b)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(b.name).bold()
                                        Text(b.timestamp.formatted()).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.subheadline)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }

                Section("Information") {
                    Text("Exporting a backup allows you to migrate your data to another device or keep a copy in your own cloud storage.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Export Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func shareBackup(_ backup: BackupMetadata) {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let zipURL = documents.appendingPathComponent("Backups/\(backup.id.uuidString).zip")

        guard FileManager.default.fileExists(atPath: zipURL.path) else { return }

        let vc = UIActivityViewController(activityItems: [zipURL], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(vc, animated: true)
        }
    }

    private func saveToFiles(_ backup: BackupMetadata) {
        // Saving to files is often handled by UIActivityViewController's "Save to Files" action.
        // For a more direct integration, UIDocumentPickerViewController could be used.
        shareBackup(backup)
    }
}
