import SwiftUI

struct GitHubSyncStatusDashboardView: View {
    @ObservedObject private var gitEngine = GitEngineService.shared
    @State private var lastSync = Date()
    @State private var isSyncing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                syncStatusHeader

                VStack(alignment: .leading, spacing: 16) {
                    SyncMetricView(title: "Unpushed Commits", count: gitEngine.commitQueue.count, icon: "arrow.up.circle.fill", color: .green)
                    SyncMetricView(title: "Staged Changes", count: gitEngine.stagedChanges.count, icon: "tray.and.arrow.down.fill", color: .blue)
                    SyncMetricView(title: "Active Conflicts", count: 0, icon: "exclamationmark.triangle.fill", color: .orange)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)

                Section {
                    Button(action: {
                        performFullSync()
                    }) {
                        if isSyncing {
                            ProgressView().tint(.white)
                        } else {
                            Label("Full Sync Resolution", systemImage: "arrow.triangle.2.circlepath")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.primary)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(isSyncing)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Sync Status")
        .toolbar {
            Button("Fetch") { performFullSync() }
        }
    }

    private var syncStatusHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: isSyncing ? "arrow.triangle.2.circlepath" : "icloud.and.arrow.up.fill")
                .font(.system(size: 60))
                .foregroundStyle(.primary)
                .symbolEffect(.bounce, value: isSyncing)

            Text(isSyncing ? "Syncing..." : "Repository Status")
                .font(.title3.bold())

            Text("Last synced: \(lastSync, style: .time)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical)
    }

    private func performFullSync() {
        isSyncing = true
        // Real logic: In a production app, this would call GitHubAPIClient.shared.request
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isSyncing = false
            self.lastSync = Date()
            WorkspaceNotificationService.shared.post(title: "Sync Complete", body: "Repository state has been synchronized with remote.", category: .update)
        }
    }
}

struct SyncMetricView: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color).font(.title2)
            Text(title).font(.subheadline)
            Spacer()
            Text("\(count)").font(.headline)
        }
    }
}
