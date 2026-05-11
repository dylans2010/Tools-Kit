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
        connectorStats = [
            ConnectorStat(name: "GitHub", totalCalls: 1245, errorCount: 12, avgLatencyMs: 180, successRate: 0.99),
            ConnectorStat(name: "Gmail", totalCalls: 890, errorCount: 5, avgLatencyMs: 220, successRate: 0.994),
            ConnectorStat(name: "REST API", totalCalls: 3500, errorCount: 45, avgLatencyMs: 150, successRate: 0.987),
            ConnectorStat(name: "Slack", totalCalls: 456, errorCount: 3, avgLatencyMs: 95, successRate: 0.993),
            ConnectorStat(name: "Calendar", totalCalls: 234, errorCount: 1, avgLatencyMs: 130, successRate: 0.996),
        ]
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
