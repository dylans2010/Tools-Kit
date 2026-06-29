import SwiftUI

struct CreateBackupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = BackupManager.shared

    @State private var name: String = ""
    @State private var type: BackupMetadata.BackupMode = .full
    @State private var selectedModules: Set<BackupModule> = Set(BackupModule.allCases)
    @State private var useBackupExtension = true
    @State private var isCreating = false
    @State private var progress: Double = 0
    @State private var statusMessage = "Waiting to start..."

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Snapshot Identity")
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                        TextField("Give your backup a name...", text: $name)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                }

                Section("Backup Format") {
                    Toggle(isOn: $useBackupExtension) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Use .backup Extension")
                            Text("Optimized for Tools-Kit ecosystem")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Picker("Type", selection: $type) {
                        Text("Full").tag(BackupMetadata.BackupMode.full)
                        Text("Incremental").tag(BackupMetadata.BackupMode.incremental)
                        Text("Selective").tag(BackupMetadata.BackupMode.selective)
                    }
                    .pickerStyle(.segmented)

                    Text(typeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                } header: {
                    Text("Snapshot Mode")
                }

                Section {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(BackupModule.allCases) { module in
                            ModuleToggle(module: module, isSelected: Binding(
                                get: { selectedModules.contains(module) },
                                set: { isSet in
                                    if isSet { selectedModules.insert(module) }
                                    else { selectedModules.remove(module) }
                                }
                            ))
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    HStack {
                        Text("Data Modules")
                        Spacer()
                        Button(selectedModules.count == BackupModule.allCases.count ? "Deselect All" : "Select All") {
                            if selectedModules.count == BackupModule.allCases.count {
                                selectedModules.removeAll()
                            } else {
                                selectedModules = Set(BackupModule.allCases)
                            }
                        }
                        .font(.caption)
                    }
                }

                if isCreating {
                    Section {
                        VStack(spacing: 16) {
                            ProgressView(value: progress)
                                .tint(.blue)

                            HStack {
                                Text(statusMessage)
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(Int(progress * 100))%")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("New Snapshot")
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
        progress = 0.05
        statusMessage = "Preparing modules..."

        Task {
            do {
                // Stage 1: Exporting
                await updateStatus("Exporting data...", p: 0.2)
                try await Task.sleep(for: .milliseconds(400))

                // Stage 2: Compressing
                await updateStatus("Compressing archive...", p: 0.5)

                let metadata = try await manager.createBackup(
                    modules: selectedModules,
                    mode: type,
                    name: name.isEmpty ? nil : name,
                    useBackupExtension: useBackupExtension
                )

                // Stage 3: Finalizing
                await updateStatus("Calculating checksum...", p: 0.9)
                try await Task.sleep(for: .milliseconds(300))

                await MainActor.run {
                    progress = 1.0
                    statusMessage = "Backup Complete"
                    isCreating = false
                    dismiss()
                }
            } catch {
                print("Backup failed: \(error)")
                await MainActor.run {
                    isCreating = false
                    statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func updateStatus(_ message: String, p: Double) async {
        await MainActor.run {
            statusMessage = message
            withAnimation {
                progress = p
            }
        }
    }
}

struct ModuleToggle: View {
    let module: BackupModule
    @Binding var isSelected: Bool

    var body: some View {
        Button {
            isSelected.toggle()
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.blue :Color.secondary)
                Text(module.rawValue.capitalized)
                    .font(.caption.bold())
                    .foregroundStyle(isSelected ? .primary : .secondary)
                Spacer()
            }
            .padding(10)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue.opacity(0.2) : Color.clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
