import SwiftUI

struct PluginAnalyticsView: View {
    @StateObject private var manager = PluginManager.shared
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedPlugin: PluginDefinition?

    var body: some View {
        List {
            Section("Overview") {
                HStack(spacing: 16) {
                    analyticsCard(title: "Total Plugins", value: "\(manager.installedPlugins.count)", icon: "puzzlepiece.extension")
                    analyticsCard(title: "Active", value: "\(manager.installedPlugins.filter(\.isEnabled).count)", icon: "bolt.fill")
                    analyticsCard(title: "Errors", value: "\(manager.installedPlugins.reduce(0) { $0 + $1.errorCount })", icon: "exclamationmark.triangle")
                }
            }

            Section("Time Range") {
                Picker("Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue.capitalized).tag(range)
                    }
                }
                .pickerStyle(.segmented)
            }

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

            Section("Execution Trends") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Plugin executions over time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(0..<7, id: \.self) { day in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.blue.opacity(0.7))
                                .frame(height: CGFloat.random(in: 20...100))
                        }
                    }
                    .frame(height: 100)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Plugin Analytics")
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
