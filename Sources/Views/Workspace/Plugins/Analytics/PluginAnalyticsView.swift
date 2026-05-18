import SwiftUI

struct PluginAnalyticsView: View {
    @StateObject private var manager = SDKPluginManager.shared
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedPlugin: PluginDefinition?

    private var totalPlugins: Int { manager.installedPlugins.count }
    private var activePlugins: Int { manager.installedPlugins.filter(\.isEnabled).count }
    private var totalErrors: Int { manager.installedPlugins.reduce(0) { $0 + $1.errorCount } }
    private var totalExecutions: Int { manager.installedPlugins.reduce(0) { $0 + $1.executionCount } }

    var body: some View {
        List {
            overviewSection
            timeRangeSection
            pluginUsageSection
            executionTrendsSection
        }
        .navigationTitle("Plugin Analytics")
    }

    private var overviewSection: some View {
        Section("Overview") {
            HStack(spacing: 16) {
                analyticsCard(title: "Total Plugins", value: "\(totalPlugins)", icon: "puzzlepiece.extension")
                analyticsCard(title: "Active", value: "\(activePlugins)", icon: "bolt.fill")
                analyticsCard(title: "Errors", value: "\(totalErrors)", icon: "exclamationmark.triangle")
            }
        }
    }

    private var timeRangeSection: some View {
        Section("Time Range") {
            Picker("Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue.capitalized).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var pluginUsageSection: some View {
        Section("Plugin Usage") {
            ForEach(manager.installedPlugins) { plugin in
                HStack {
                    VStack(alignment: .leading) {
                        Text(plugin.name)
                            .font(.headline)
                        Text(plugin.isEnabled ? "Active" : "Disabled")
                            .font(.caption)
                            .foregroundStyle(plugin.isEnabled ? .green : .secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(plugin.executionCount) runs")
                            .font(.subheadline)
                        if plugin.errorCount > 0 {
                            Text("\(plugin.errorCount) errors")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
    }

    private var executionTrendsSection: some View {
        Section("Execution Trends") {
            if totalExecutions == 0 {
                Text("No execution data yet. Run plugins to see trends.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                executionTrendsChart
            }
        }
    }

    private var executionTrendsChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Plugin executions by plugin")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .bottom, spacing: 4) {
                let maxCount = max(manager.installedPlugins.map(\.executionCount).max() ?? 1, 1)
                ForEach(manager.installedPlugins.prefix(10)) { plugin in
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.blue.opacity(0.7))
                            .frame(height: max(4, CGFloat(plugin.executionCount) / CGFloat(maxCount) * 100))
                        Text(String(plugin.name.prefix(3)))
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 120)
        }
        .padding(.vertical, 8)
    }

    private func analyticsCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            Text(value)
                .font(.title.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private enum TimeRange: String, CaseIterable {
    case day, week, month, year
}
