import SwiftUI

struct BackupDetailView: View {
    let backup: BackupMetadata
    @StateObject private var manager = BackupManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingRestore = false
    @State private var showingExport = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "doc.zipper")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)

                    Text(backup.name)
                        .font(.title3.bold())

                    Text(backup.id.uuidString)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            Section("Overview") {
                LabeledContent("Date", value: backup.timestamp.formatted())
                LabeledContent("Size", value: ByteCountFormatter.string(fromByteCount: backup.totalSizeCompressed, countStyle: .file))
                LabeledContent("Uncompressed", value: ByteCountFormatter.string(fromByteCount: backup.totalSizeRaw, countStyle: .file))
                LabeledContent("Mode", value: backup.mode.rawValue.capitalized)
                LabeledContent("App Version", value: "\(backup.appVersion) (\(backup.buildNumber))")
            }

            Section("Module Breakdown") {
                ForEach(backup.moduleSizes.keys.sorted(), id: \.self) { key in
                    HStack {
                        Text(key.capitalized)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(ByteCountFormatter.string(fromByteCount: backup.moduleSizes[key] ?? 0, countStyle: .file))
                                .font(.subheadline)
                            Text("\(backup.moduleFileCounts[key] ?? 0) files")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Device Info") {
                LabeledContent("Device", value: backup.deviceInfo)
                LabeledContent("OS Version", value: backup.osVersion)
                LabeledContent("Integrity", value: backup.checksum.isEmpty ? "Unknown" : "Verified")
            }

            Section {
                Button {
                    manager.toggleStar(for: backup)
                } label: {
                    Label(backup.isStarred ? "Unstar Backup" : "Star Backup", systemImage: backup.isStarred ? "star.fill" : "star")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)

                Button {
                    showingRestore = true
                } label: {
                    Label("Restore This Backup", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    showingExport = true
                } label: {
                    Label("Export .zip", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    manager.deleteBackup(metadata: backup)
                    dismiss()
                } label: {
                    Label("Delete Backup", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Backup Details")
        .sheet(isPresented: $showingRestore) {
            RestoreBackupView(selectedBackup: backup)
        }
        .sheet(isPresented: $showingExport) {
            BackupExportView(backup: backup)
        }
    }
}
