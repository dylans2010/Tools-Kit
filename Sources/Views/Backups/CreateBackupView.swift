import SwiftUI

struct CreateBackupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = BackupManager.shared

    @State private var name: String = ""
    @State private var type: BackupMetadata.BackupMode = .full
    @State private var selectedModules: Set<BackupModule> = Set(BackupModule.allCases)
    @State private var isCreating = false
    @State private var progress: Double = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Backup Identity") {
                    TextField("Backup Name (Optional)", text: $name)
                }

                Section("Backup Type") {
                    Picker("Type", selection: $type) {
                        Text("Full").tag(BackupMetadata.BackupMode.full)
                        Text("Incremental").tag(BackupMetadata.BackupMode.incremental)
                        Text("Selective").tag(BackupMetadata.BackupMode.selective)
                    }
                    .pickerStyle(.segmented)

                    Text(typeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Modules to Include") {
                    ForEach(BackupModule.allCases) { module in
                        Toggle(module.rawValue.capitalized, isOn: Binding(
                            get: { selectedModules.contains(module) },
                            set: { isSet in
                                if isSet { selectedModules.insert(module) }
                                else { selectedModules.remove(module) }
                            }
                        ))
                    }
                }

                if isCreating {
                    Section {
                        VStack(spacing: 12) {
                            ProgressView(value: progress)
                            Text("Creating backup...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Create Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        startBackup()
                    }
                    .disabled(isCreating || selectedModules.isEmpty)
                }
            }
        }
    }

    private var typeDescription: String {
        switch type {
        case .full: return "A complete snapshot of all selected data."
        case .incremental: return "Only backs up data changed since the last backup."
        case .selective: return "Allows granular control over which modules are included."
        }
    }

    private func startBackup() {
        isCreating = true
        progress = 0.1

        Task {
            do {
                // Simulate some progress
                for i in 1...5 {
                    try? await Task.sleep(for: .milliseconds(200))
                    await MainActor.run { progress = Double(i) * 0.15 }
                }

                _ = try await manager.createBackup(
                    modules: selectedModules,
                    mode: type,
                    name: name.isEmpty ? nil : name
                )

                await MainActor.run {
                    progress = 1.0
                    isCreating = false
                    dismiss()
                }
            } catch {
                print("Backup failed: \(error)")
                await MainActor.run { isCreating = false }
            }
        }
    }
}
