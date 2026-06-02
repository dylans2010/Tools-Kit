import SwiftUI

struct PluginUsageAnalyticsView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                summaryCards

                VStack(alignment: .leading, spacing: 16) {
                    Text("Top Performing Plugins")
                        .font(.headline)

                    ForEach(store.pluginAnalytics) { metric in
                        let plugin = store.plugins.first(where: { $0.id == metric.pluginID })
                        PluginMetricRow(name: plugin?.name ?? "Unknown", metric: metric)
                    }

                    if store.pluginAnalytics.isEmpty {
                        Text("No analytics data available.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .navigationTitle("Plugin Analytics")
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear(perform: generateMockData)
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            MetricCard(title: "Total Installs", value: "\(store.pluginAnalytics.reduce(0) { $0 + $1.installsCount })", icon: "arrow.down.circle", color: .blue)
            MetricCard(title: "Active Users", value: "\(store.pluginAnalytics.reduce(0) { $0 + $1.activeUsers })", icon: "person.2.fill", color: .green)
        }
    }

    private func generateMockData() {
        if store.pluginAnalytics.isEmpty && !store.plugins.isEmpty {
            let mock = store.plugins.prefix(3).map { plugin in
                PluginAnalytics(
                    pluginID: plugin.id,
                    installsCount: Int.random(in: 100...5000),
                    activeUsers: Int.random(in: 50...2000),
                    crashCount: Int.random(in: 0...5),
                    averageLatency: Double.random(in: 0.01...0.1)
                )
            }
            store.savePluginAnalytics(mock)
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 4) {
                Text(value).font(.title3.bold())
                Text(title).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct PluginMetricRow: View {
    let name: String
    let metric: PluginAnalytics

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(name).font(.subheadline.bold())
                Spacer()
                Text("\(metric.installsCount) installs").font(.caption2).foregroundStyle(.secondary)
            }

            ProgressView(value: Double(metric.activeUsers), total: Double(metric.installsCount))
                .tint(.blue)

            HStack {
                Label("\(metric.crashCount) crashes", systemImage: "bolt.trianglebadge.exclamationmark")
                Spacer()
                Label(String(format: "%.0fms", metric.averageLatency * 1000), systemImage: "timer")
            }
            .font(.system(size: 8))
            .foregroundStyle(.tertiary)
        }
        .padding(.bottom, 8)
    }
}
