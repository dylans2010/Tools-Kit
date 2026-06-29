import SwiftUI

struct RestoreBackupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = BackupManager.shared

    @State var selectedBackup: BackupMetadata?
    @State private var restoreType: RestoreType = .full
    @State private var selectedModules: Set<BackupModule> = []
    @State private var isRestoring = false
    @State private var progress: Double = 0
    @State private var showConfirmation = false
    @State private var showingFilePicker = false
    @State private var validationError: String?

    enum RestoreType {
        case full, partial
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let backup = selectedBackup {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title2)
                                    .foregroundStyle(.green)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(backup.name)
                                        .font(.headline)
                                    Text("Verified Backup Snapshot")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Change") { selectedBackup = nil }
                                    .font(.caption.bold())
                                    .buttonStyle(.bordered)
                            }

                            Divider()

                            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                                GridRow {
                                    InfoLabel(title: "Date", value: backup.timestamp.formatted())
                                    InfoLabel(title: "Version", value: backup.appVersion)
                                }
                                GridRow {
                                    InfoLabel(title: "Device", value: backup.deviceInfo)
                                    InfoLabel(title: "Size", value: formatSize(backup.totalSizeCompressed))
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 16) {
                            NavigationLink {
                                List(manager.availableBackups) { backup in
                                    Button {
                                        selectedBackup = backup
                                        selectedModules = backup.restoreScope
                                        dismiss()
                                    } label: {
                                        BackupRow(backup: backup)
                                    }
                                }
                                .navigationTitle("Local Backups")
                            } label: {
                                Label("Browse Local Backups", systemImage: "internaldrive.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button {
                                showingFilePicker = true
                            } label: {
                                Label("Import .backup or .zip", systemImage: "folder.badge.plus")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Source Selection")
                }

                if let backup = selectedBackup {
                    Section("Restore Strategy") {
                        Picker("Type", selection: $restoreType) {
                            Text("Full").tag(RestoreType.full)
                            Text("Selective").tag(RestoreType.partial)
                        }
                        .pickerStyle(.segmented)

                        Text(restoreType == .full ? "Overwrites all current data with the snapshot content." : "Allows you to choose specific modules to restore.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if restoreType == .partial {
                        Section("Included Modules") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(Array(backup.restoreScope)) { module in
                                    ModuleToggle(module: module, isSelected: Binding(
                                        get: { selectedModules.contains(module) },
                                        set: { isSet in
                                            if isSet { selectedModules.insert(module) }
                                            else { selectedModules.remove(module) }
                                        }
                                    ))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Safety First", systemImage: "shield.checkered")
                                .font(.headline)
                                .foregroundStyle(.green)
                            Text("A 'Safety Restore' snapshot will be created automatically. You can always roll back if needed.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    Section {
                        Button {
                            showConfirmation = true
                        } label: {
                            Text("Confirm & Start Restore")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(isRestoring || (restoreType == .partial && selectedModules.isEmpty))
                    }
                    .listRowBackground(Color.clear)
                }

                if isRestoring {
                    Section {
                        VStack(spacing: 16) {
                            ProgressView(value: progress)
                                .tint(.blue)
                            Text("Restoring System Assets...")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }

                if let error = validationError {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Data Recovery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Final Confirmation", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Restore Now", role: .destructive) { performRestore() }
            } message: {
                Text("This action will replace your current data. This process cannot be interrupted.")
            }
            .sheet(isPresented: $showingFilePicker) {
                DocumentPicker { url in
                    Task {
                        do {
                            let metadata = try await manager.importBackupFile(from: url)
                            await MainActor.run {
                                self.selectedBackup = metadata
                                self.selectedModules = metadata.restoreScope
                                self.validationError = nil
                            }
                        } catch {
                            await MainActor.run {
                                self.validationError = "Invalid File: \(error.localizedDescription)"
                            }
                        }
                    }
                }
            }
        }
    }

    private func performRestore() {
        guard let backup = selectedBackup else { return }
        isRestoring = true
        progress = 0.1

        Task {
            do {
                // Safety first
                try await manager.createBackup(modules: Set(BackupModule.allCases), mode: .full, name: "Auto-Safety (Pre-Restore)")

                await MainActor.run { progress = 0.4 }

                try await manager.restoreBackup(metadata: backup, modules: selectedModules)

                await MainActor.run {
                    progress = 1.0
                    isRestoring = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    validationError = "Restore Failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func formatSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

struct InfoLabel: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.subheadline)
                .lineLimit(1)
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.zip, .init("com.toolskit.backup")!])
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        init(_ parent: DocumentPicker) { self.parent = parent }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first { parent.onPick(url) }
        }
    }
}
