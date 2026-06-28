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

    enum RestoreType {
        case full, partial
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Select Backup") {
                    if let backup = selectedBackup {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(backup.name).bold()
                                Text(backup.timestamp.formatted()).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Change") { selectedBackup = nil }
                                .font(.caption)
                        }
                    } else {
                        VStack(spacing: 12) {
                            NavigationLink("Choose from local backups...") {
                                List(manager.availableBackups) { backup in
                                    Button {
                                        selectedBackup = backup
                                        selectedModules = backup.restoreScope
                                        dismiss()
                                    } label: {
                                        VStack(alignment: .leading) {
                                            Text(backup.name).bold()
                                            Text(backup.timestamp.formatted()).font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                    .foregroundStyle(.primary)
                                }
                                .navigationTitle("Select Backup")
                            }

                            Button {
                                showingFilePicker = true
                            } label: {
                                Label("Import from Files app...", systemImage: "folder.badge.plus")
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }

                if let backup = selectedBackup {
                    Section("Restore Type") {
                        Picker("Type", selection: $restoreType) {
                            Text("Full Restore").tag(RestoreType.full)
                            Text("Partial Restore").tag(RestoreType.partial)
                        }
                        .pickerStyle(.segmented)
                    }

                    if restoreType == .partial {
                        Section("Modules to Restore") {
                            ForEach(Array(backup.restoreScope)) { module in
                                Toggle(module.rawValue.capitalized, isOn: Binding(
                                    get: { selectedModules.contains(module) },
                                    set: { isSet in
                                        if isSet { selectedModules.insert(module) }
                                        else { selectedModules.remove(module) }
                                    }
                                ))
                            }
                        }
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Safety Snapshot", systemImage: "shield.fill")
                                .font(.headline)
                                .foregroundStyle(.green)
                            Text("A temporary 'Undo Restore' snapshot will be created before starting the restore process.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    Section {
                        Button {
                            showConfirmation = true
                        } label: {
                            Text("Start Restore")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isRestoring || (restoreType == .partial && selectedModules.isEmpty))
                    }
                    .listRowBackground(Color.clear)
                }

                if isRestoring {
                    Section {
                        VStack(spacing: 12) {
                            ProgressView(value: progress)
                            Text("Restoring system state...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Restore Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Confirm Restore", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Restore Now") { performRestore() }
            } message: {
                Text("This will replace current data in the selected modules. Are you sure you want to proceed?")
            }
            .sheet(isPresented: $showingFilePicker) {
                DocumentPicker { url in
                    Task {
                        do {
                            let metadata = try await manager.importBackupFile(from: url)
                            await MainActor.run {
                                self.selectedBackup = metadata
                                self.selectedModules = metadata.restoreScope
                            }
                        } catch {
                            print("Import failed: \(error)")
                        }
                    }
                }
            }
        }
    }

    private func performRestore() {
        guard let backup = selectedBackup else { return }
        isRestoring = true
        progress = 0

        Task {
            do {
                _ = try await manager.createBackup(modules: Set(BackupModule.allCases), mode: .full, name: "Undo Restore Safety")

                try await manager.restoreBackup(metadata: backup, modules: selectedModules)

                await MainActor.run {
                    isRestoring = false
                    dismiss()
                }
            } catch {
                print("Restore failed: \(error)")
                await MainActor.run { isRestoring = false }
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.zip])
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
