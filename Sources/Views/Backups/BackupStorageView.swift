import SwiftUI

struct BackupStorageView: View {
    @StateObject private var manager = BackupManager.shared
    @State private var totalSize: Int64 = 0

    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                        .font(.system(size: 34, weight: .bold))
                    Text("Total Storage Used")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            Section("Usage by Module (Aggregated)") {
                let moduleUsage = aggregateUsage()
                ForEach(moduleUsage.keys.sorted(by: { moduleUsage[$0]! > moduleUsage[$1]! }), id: \.self) { module in
                    HStack {
                        Text(module.capitalized)
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: moduleUsage[module] ?? 0, countStyle: .file))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Maintenance Suggestions") {
                if manager.availableBackups.count > 3 {
                    Button {
                        deleteOldBackups()
                    } label: {
                        Label("Delete Backups Older Than 30 Days", systemImage: "trash")
                    }

                    Button {
                        cleanupStorage()
                    } label: {
                        Label("Force Storage Cleanup", systemImage: "arrow.down.right.and.arrow.up.left")
                    }
                } else {
                    Text("No suggestions. Storage usage is low.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Storage Usage")
        .onAppear {
            totalSize = manager.availableBackups.reduce(0) { $0 + $1.totalSizeCompressed }
        }
    }

    private func aggregateUsage() -> [String: Int64] {
        var usage: [String: Int64] = [:]
        for backup in manager.availableBackups {
            for (module, size) in backup.moduleSizes {
                usage[module, default: 0] += size
            }
        }
        return usage
    }

    private func deleteOldBackups() {
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        for backup in manager.availableBackups {
            if backup.timestamp < thirtyDaysAgo && !backup.isStarred {
                manager.deleteBackup(metadata: backup)
            }
        }
    }

    private func cleanupStorage() {
        // Trigger a fresh load and validation
        manager.loadBackups()
        totalSize = manager.availableBackups.reduce(0) { $0 + $1.totalSizeCompressed }
    }
}
