import SwiftUI

struct ConnectorSyncStatusView: View {
    @State private var syncJobs: [SyncJob] = []
    @State private var isRefreshing = false

    var body: some View {
        List {
            Section("Sync Overview") {
                HStack(spacing: 16) {
                    syncStatCard(title: "Active", value: "\(syncJobs.filter { $0.status == .running }.count)", color: .blue)
                    syncStatCard(title: "Completed", value: "\(syncJobs.filter { $0.status == .completed }.count)", color: .green)
                    syncStatCard(title: "Failed", value: "\(syncJobs.filter { $0.status == .failed }.count)", color: .red)
                }
            }

            Section("Active Syncs") {
                let active = syncJobs.filter { $0.status == .running }
                if active.isEmpty {
                    Text("No active sync operations")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(active) { job in
                        syncJobRow(job)
                    }
                }
            }

            Section("Recent Syncs") {
                ForEach(syncJobs.filter { $0.status != .running }) { job in
                    syncJobRow(job)
                }
            }
        }
        .navigationTitle("Sync Status")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { refresh() } label: {
                    if isRefreshing { ProgressView() } else { Image(systemName: "arrow.clockwise") }
                }
            }
        }
        .task { loadSyncJobs() }
    }

    private func syncJobRow(_ job: SyncJob) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: job.status.icon)
                    .foregroundStyle(job.status.color)
                Text(job.connectorName)
                    .font(.headline)
                Spacer()
                Text(job.status.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(job.status.color.opacity(0.15))
                    .clipShape(Capsule())
            }
            if job.status == .running {
                ProgressView(value: job.progress)
                    .tint(.blue)
            }
            HStack {
                Text("\(job.recordsSynced) records")
                    .font(.caption)
                Spacer()
                Text(job.lastUpdated.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func syncStatCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold()).foregroundStyle(color)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func refresh() {
        isRefreshing = true
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run { isRefreshing = false }
        }
    }

    private func loadSyncJobs() {
        syncJobs = [
            SyncJob(connectorName: "GitHub", status: .running, progress: 0.65, recordsSynced: 234, lastUpdated: Date()),
            SyncJob(connectorName: "Gmail", status: .completed, progress: 1.0, recordsSynced: 1520, lastUpdated: Date().addingTimeInterval(-3600)),
            SyncJob(connectorName: "Calendar", status: .completed, progress: 1.0, recordsSynced: 89, lastUpdated: Date().addingTimeInterval(-7200)),
            SyncJob(connectorName: "Slack", status: .failed, progress: 0.3, recordsSynced: 45, lastUpdated: Date().addingTimeInterval(-1800)),
        ]
    }
}

private struct SyncJob: Identifiable {
    let id = UUID()
    let connectorName: String
    let status: SyncStatus
    let progress: Double
    let recordsSynced: Int
    let lastUpdated: Date
}

private enum SyncStatus: String {
    case running, completed, failed, pending

    var icon: String {
        switch self {
        case .running: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .pending: return "clock"
        }
    }

    var color: Color {
        switch self {
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        case .pending: return .orange
        }
    }
}
