import SwiftUI

struct AutoBackupSettingsView: View {
    @AppStorage("autoBackupEnabled") private var enabled = false
    @AppStorage("autoBackupFrequency") private var frequency = 24 // hours
    @AppStorage("autoBackupOverwrite") private var overwrite = true
    @AppStorage("autoBackupLastRun") private var lastRun: Double = 0

    @State private var isCreating = false
    @State private var backupToShare: URL?
    @State private var showingShareSheet = false

    var body: some View {
        Form {
            Section {
                Toggle("Automatic Backups", isOn: $enabled)
                Text("Backups will run in the background when the app is active and the frequency interval has passed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if enabled {
                Section("Frequency") {
                    Picker("Run Every", selection: $frequency) {
                        Text("12 Hours").tag(12)
                        Text("24 Hours").tag(24)
                        Text("48 Hours").tag(48)
                        Text("Weekly").tag(168)
                    }

                    if lastRun > 0 {
                        LabeledContent("Last Run", value: Date(timeIntervalSince1970: lastRun).formatted())
                    } else {
                        LabeledContent("Last Run", value: "Never")
                    }
                }

                Section("Behavior") {
                    Toggle("Overwrite Same-Day Backups", isOn: $overwrite)
                    Text("When enabled, only one automatic backup will be kept per day to save space.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    runManualBackup()
                } label: {
                    HStack {
                        if isCreating {
                            ProgressView().padding(.trailing, 8)
                        }
                        Text(isCreating ? "Backing up..." : "Back Up Now")
                    }
                }
                .disabled(isCreating)
            }
        }
        .navigationTitle("Auto Backups")
        .sheet(isPresented: $showingShareSheet) {
            if let url = backupToShare {
                BackupShareSheet(activityItems: [url])
            }
        }
    }

    private func runManualBackup() {
        isCreating = true
        Task {
            do {
                let metadata = try await BackupManager.shared.createBackup(
                    modules: Set(BackupModule.allCases),
                    mode: .full,
                    name: "Manual Settings Snapshot"
                )
                await MainActor.run {
                    self.backupToShare = BackupManager.shared.getZipURL(for: metadata)
                    self.isCreating = false
                    self.showingShareSheet = true
                }
            } catch {
                print("Manual backup failed: \(error)")
                await MainActor.run { isCreating = false }
            }
        }
    }
}

struct BackupShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
