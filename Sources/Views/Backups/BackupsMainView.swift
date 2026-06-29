import SwiftUI

struct BackupsMainView: View {
    @StateObject private var manager = BackupManager.shared
    @State private var showingCreate = false

    private var totalBackupSize: Int64 {
        manager.availableBackups.reduce(0) { $0 + $1.totalSizeCompressed }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Modern Hero Section
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Image(systemName: "archivebox.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue.gradient)
                    }

                    VStack(spacing: 4) {
                        Text("System Snapshots")
                            .font(.title2.bold())
                        Text("\(manager.availableBackups.count) Backups • \(formatSize(totalBackupSize))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        showingCreate = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create New Backup")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24))

                // Storage Insight Card
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cloud & Local Storage")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text("Optimized and Compressed")
                            .font(.subheadline.bold())
                    }
                    Spacer()
                    Image(systemName: "bolt.shield.fill")
                        .foregroundStyle(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Quick Access Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    QuickActionCard(title: "Restore", icon: "arrow.counterclockwise", color: .orange, destination: RestoreBackupView())
                    QuickActionCard(title: "History", icon: "calendar.day.timeline.left", color: .purple, destination: BackupTimelineView())
                    QuickActionCard(title: "Integrity", icon: "checkmark.shield.fill", color: .green, destination: BackupIntegrityView())
                    QuickActionCard(title: "Settings", icon: "gearshape.fill", color: .gray, destination: AutoBackupSettingsView())
                }

                // Recent Backups List
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Snapshots")
                        .font(.headline)
                        .padding(.horizontal)

                    if manager.availableBackups.isEmpty {
                        ContentUnavailableView("No Backups Yet", systemImage: "doc.badge.plus", description: Text("Secure your data by creating your first snapshot."))
                            .frame(height: 200)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(manager.availableBackups.prefix(3)) { backup in
                                NavigationLink(destination: BackupDetailView(backup: backup)) {
                                    RecentBackupRow(backup: backup)
                                }
                            }

                            NavigationLink(destination: BackupListView()) {
                                Text("View All Backups")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.blue)
                                    .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Backups")
        .sheet(isPresented: $showingCreate) {
            CreateBackupView()
        }
    }

    private func formatSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

struct QuickActionCard<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct RecentBackupRow: View {
    let backup: BackupMetadata

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(backup.isStarred ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: backup.isStarred ? "star.fill" : "doc.fill")
                    .foregroundStyle(backup.isStarred ? .orange : .blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(backup.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text(backup.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
