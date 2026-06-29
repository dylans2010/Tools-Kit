import SwiftUI

struct BackupIntegrityView: View {
    @State private var manager = BackupManager.shared
    @State private var isValidating = false
    @State private var results: [UUID: ValidationResult] = [:]
    @State private var isRepairing = false

    enum ValidationResult {
        case valid, corrupted(String), pending
    }

    var body: some View {
        List {
            Section {
                Button {
                    validateAll()
                } label: {
                    if isValidating {
                        ProgressView().tint(.white)
                    } else {
                        Text("Validate All Backups")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isValidating || manager.availableBackups.isEmpty)
            }
            .listRowBackground(Color.clear)

            Section("Backup Integrity Status") {
                if manager.availableBackups.isEmpty {
                    Text("No backups to validate.").foregroundStyle(.secondary)
                } else {
                    ForEach(manager.availableBackups) { backup in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(backup.name).font(.subheadline).bold()
                                Text(backup.timestamp.formatted()).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            statusLabel(for: backup.id)
                        }
                    }
                }
            }

            Section("Maintenance") {
                Button(role: .destructive) {
                    repairCorrupted()
                } label: {
                    HStack {
                        if isRepairing {
                            ProgressView().padding(.trailing, 8)
                        }
                        Label(isRepairing ? "Repairing..." : "Attempt Repair on Corrupted", systemImage: "wrench.and.screwdriver")
                    }
                }
                .disabled(isRepairing || results.values.filter { if case .corrupted = $0 { return true }; return false }.isEmpty)

                Text("Repair will attempt to re-index metadata and verify ZIP file accessibility.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Integrity Check")
    }

    @ViewBuilder
    private func statusLabel(for id: UUID) -> some View {
        if let result = results[id] {
            switch result {
            case .valid:
                Label("Healthy", systemImage: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
            case .corrupted(let msg):
                Label("Corrupted", systemImage: "xmark.octagon.fill").foregroundStyle(.red).font(.caption)
            case .pending:
                ProgressView().scaleEffect(0.7)
            }
        } else {
            Text("Not Checked").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func validateAll() {
        isValidating = true
        Task {
            for backup in manager.availableBackups {
                await MainActor.run { results[backup.id] = .pending }

                let zipURL = manager.getArchiveURL(for: backup)
                let exists = FileManager.default.fileExists(atPath: zipURL.path)
                let size = (try? FileManager.default.attributesOfItem(atPath: zipURL.path)[.size] as? Int64) ?? 0

                let result: ValidationResult = (exists && size > 0) ? .valid : .corrupted("File missing or empty")
                await MainActor.run { results[backup.id] = result }
            }
            await MainActor.run { isValidating = false }
        }
    }

    private func repairCorrupted() {
        isRepairing = true
        Task {
            for (id, result) in results {
                if case .corrupted = result {
                    // Try to re-load or re-index
                    await MainActor.run { results[id] = .pending }
                    try? await Task.sleep(for: .milliseconds(500))

                    // Simple repair: refresh the manager and re-check
                    await MainActor.run {
                        manager.loadBackups()
                        validateAll()
                    }
                }
            }
            await MainActor.run { isRepairing = false }
        }
    }
}
