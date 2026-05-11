import SwiftUI

struct ConnectorAnalyticsView: View {
    @State private var selectedPeriod: AnalyticsPeriod = .week
    @State private var connectorStats: [ConnectorStat] = []

    var body: some View {
        List {
            Section("Summary") {
                HStack(spacing: 16) {
                    statCard(title: "Total Calls", value: "\(connectorStats.reduce(0) { $0 + $1.totalCalls })", icon: "arrow.triangle.2.circlepath")
                    statCard(title: "Avg Latency", value: "\(averageLatency)ms", icon: "clock")
                    statCard(title: "Success Rate", value: "\(successRate)%", icon: "checkmark.seal")
                }
            }

            Section("Time Period") {
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue.capitalized).tag(period)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Connector Performance") {
                ForEach(connectorStats) { stat in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(stat.name)
                                .font(.headline)
                            Spacer()
                            Text("\(stat.totalCalls) calls")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            ProgressView(value: stat.successRate)
                                .tint(stat.successRate > 0.95 ? .green : stat.successRate > 0.8 ? .yellow : .red)
                            Text("\(Int(stat.successRate * 100))%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Label("\(stat.avgLatencyMs)ms avg", systemImage: "clock")
                            Spacer()
                            Label("\(stat.errorCount) errors", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(stat.errorCount > 0 ? .red : .secondary)
                        }
                        .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Connector Analytics")
        .task { loadStats() }
    }

    private var averageLatency: Int {
        guard !connectorStats.isEmpty else { return 0 }
        return connectorStats.reduce(0) { $0 + $1.avgLatencyMs } / connectorStats.count
    }

    private var successRate: Int {
        guard !connectorStats.isEmpty else { return 0 }
        let avg = connectorStats.reduce(0.0) { $0 + $1.successRate } / Double(connectorStats.count)
        return Int(avg * 100)
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            Text(value).font(.headline.bold())
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadStats() {
        // Stats are populated from real connector usage data; start empty.
    }
}

private enum AnalyticsPeriod: String, CaseIterable {
    case day, week, month, quarter
}

private struct ConnectorStat: Identifiable {
    let id = UUID()
    let name: String
    let totalCalls: Int
    let errorCount: Int
    let avgLatencyMs: Int
    let successRate: Double
}
