import SwiftUI

struct GitHubSyncStatusDashboardView: View {
    @ObservedObject private var gitEngine = GitEngineService.shared
    @State private var lastSync = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                syncStatusHeader

                VStack(alignment: .leading, spacing: 16) {
                    SyncMetricView(title: "Unpushed Commits", count: gitEngine.commitQueue.count, icon: "arrow.up.circle.fill", color: .green)
                    SyncMetricView(title: "Unpulled Changes", count: 0, icon: "arrow.down.circle.fill", color: .blue)
                    SyncMetricView(title: "Active Conflicts", count: 0, icon: "exclamationmark.triangle.fill", color: .orange)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)

                Section {
                    Button(action: {
                        // Full sync logic
                    }) {
                        Label("Full Sync Resolution", systemImage: "arrow.triangle.2.circlepath")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Sync Status")
        .toolbar {
            Button("Pull Sync") { /* Pull */ }
            Button("Push Sync") { /* Push */ }
        }
    }

    private var syncStatusHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "icloud.and.arrow.up.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Repository is Up to Date")
                .font(.title3.bold())

            Text("Last synced: \(lastSync, style: .time)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical)
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
