import SwiftUI

struct BackupsMainView: View {
    @StateObject private var manager = BackupManager.shared
    @State private var showingCreate = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 20) {
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    VStack(spacing: 8) {
                        Text("App Data Backups")
                            .font(.title2.bold())
                        Text("Keep your workspace, mail, and AI data safe with full system snapshots.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        showingCreate = true
                    } label: {
                        Text("Create Backup Now")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .listRowBackground(Color.clear)

            Section("Quick Actions") {
                if let latestStarred = manager.availableBackups.first(where: { $0.isStarred }) {
                    NavigationLink(destination: BackupDetailView(backup: latestStarred)) {
                        Label("Starred: \(latestStarred.name)", systemImage: "star.fill")
                            .foregroundStyle(.orange)
                    }
                }

                NavigationLink(destination: BackupListView()) {
                    Label("View All Backups", systemImage: "list.bullet")
                }
                NavigationLink(destination: RestoreBackupView()) {
                    Label("Restore from File", systemImage: "arrow.counterclockwise")
                }
            }

            Section("Management") {
                NavigationLink(destination: AutoBackupSettingsView()) {
                    Label("Automatic Backups", systemImage: "clock.badge.checkmark")
                }
                NavigationLink(destination: BackupStorageView()) {
                    Label("Storage Usage", systemImage: "chart.pie.fill")
                }
                NavigationLink(destination: BackupTimelineView()) {
                    Label("History Timeline", systemImage: "calendar.day.timeline.left")
                }
            }

            Section("Tools") {
                NavigationLink(destination: BackupIntegrityView()) {
                    Label("Integrity Check", systemImage: "checkmark.shield")
                }
                NavigationLink(destination: BackupCompareView()) {
                    Label("Compare Backups", systemImage: "arrow.left.and.right.circle")
                }
                NavigationLink(destination: BackupExportView(backup: nil)) {
                    Label("Export & Migration", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationTitle("Backups")
        .sheet(isPresented: $showingCreate) {
            CreateBackupView()
        }
    }
}
