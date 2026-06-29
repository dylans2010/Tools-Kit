import SwiftUI

struct BackupListView: View {
    @StateObject private var manager = BackupManager.shared
    @State private var grouping: Grouping = .today

    enum Grouping: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case older = "Older"
    }

    var body: some View {
        List {
            if manager.availableBackups.isEmpty {
                ContentUnavailableView("No Backups", systemImage: "archivebox", description: Text("You haven't created any backups yet."))
            } else {
                ForEach(groupedBackups.keys.sorted(by: sortGrouping), id: \.self) { key in
                    Section(key.rawValue) {
                        ForEach(groupedBackups[key] ?? []) { backup in
                            NavigationLink(destination: BackupDetailView(backup: backup)) {
                                BackupListRow(backup: backup)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("All Backups")
        .onAppear { manager.loadBackups() }
    }

    private var groupedBackups: [Grouping: [BackupMetadata]] {
        var grouped: [Grouping: [BackupMetadata]] = [:]
        let calendar = Calendar.current
        let now = Date()

        for backup in manager.availableBackups {
            let group: Grouping
            if calendar.isDateInToday(backup.timestamp) {
                group = .today
            } else if calendar.isDate(backup.timestamp, equalTo: now, toGranularity: .weekOfYear) {
                group = .thisWeek
            } else if calendar.isDate(backup.timestamp, equalTo: now, toGranularity: .month) {
                group = .thisMonth
            } else {
                group = .older
            }

            grouped[group, default: []].append(backup)
        }
        return grouped
    }

    private func sortGrouping(_ a: Grouping, _ b: Grouping) -> Bool {
        let order: [Grouping] = [.today, .thisWeek, .thisMonth, .older]
        return (order.firstIndex(of: a) ?? 0) < (order.firstIndex(of: b) ?? 0)
    }
}

struct BackupListRow: View {
    let backup: BackupMetadata

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(backup.name)
                    .font(.headline)
                HStack {
                    Text(backup.timestamp, style: .date)
                    Text("•")
                    Text(ByteCountFormatter.string(fromByteCount: backup.totalSizeCompressed, countStyle: .file))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if backup.mode == .full {
                Text("FULL")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}
