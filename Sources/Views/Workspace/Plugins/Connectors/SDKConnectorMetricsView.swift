// ToolsKit — SDKConnectorMetricsView.swift
// SDK Expansion — Phase 4

import SwiftUI

struct SDKConnectorMetricsView: View {
    @StateObject private var metricsTracker = SDKConnectorMetricsTracker.shared

    var body: some View {
        List {
            overviewSection
            connectorsSection
            actionsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Connector Metrics")
    }

    private var overviewSection: some View {
        Section("Overview") {
            LabeledContent("Total Requests", value: "\(metricsTracker.totalRequests)")
            LabeledContent("Tracked Connectors", value: "\(metricsTracker.allMetrics.count)")

            if !metricsTracker.allMetrics.isEmpty {
                let totalSuccess = metricsTracker.allMetrics.reduce(0) { $0 + $1.successfulRequests }
                let totalFailed = metricsTracker.allMetrics.reduce(0) { $0 + $1.failedRequests }
                let totalAll = totalSuccess + totalFailed
                let rate = totalAll > 0 ? Double(totalSuccess) / Double(totalAll) : 0

                LabeledContent("Overall Success Rate", value: String(format: "%.1f%%", rate * 100))
                LabeledContent("Successful", value: "\(totalSuccess)")
                LabeledContent("Failed", value: "\(totalFailed)")
            }
        }
    }

    private var connectorsSection: some View {
        Section("Connector Details") {
            if metricsTracker.allMetrics.isEmpty {
                ContentUnavailableView(
                    "No Metrics",
                    systemImage: "chart.bar",
                    description: Text("Connector metrics will appear here as requests are made.")
                )
            } else {
                ForEach(metricsTracker.allMetrics) { metrics in
                    ConnectorMetricsRow(metrics: metrics)
                }
            }
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            Button(role: .destructive) {
                metricsTracker.resetAll()
            } label: {
                Label("Reset All Metrics", systemImage: "trash")
            }
        }
    }
}

private struct ConnectorMetricsRow: View {
    let metrics: SDKConnectorMetricsSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(metrics.connectorName)
                    .font(.subheadline.bold())
                Spacer()
                Text("\(metrics.totalRequests) requests")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                metricColumn(label: "Success", value: "\(metrics.successfulRequests)", color: .green)
                metricColumn(label: "Failed", value: "\(metrics.failedRequests)", color: .red)
                metricColumn(label: "Rate", value: String(format: "%.0f%%", metrics.successRate * 100), color: .blue)
            }

            HStack(spacing: 16) {
                latencyColumn(label: "Avg", value: metrics.averageLatency)
                latencyColumn(label: "P95", value: metrics.p95Latency)
                latencyColumn(label: "Min", value: metrics.minLatency)
                latencyColumn(label: "Max", value: metrics.maxLatency)
            }

            if metrics.totalRequests > 0 {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: geometry.size.width * metrics.successRate)
                        Rectangle()
                            .fill(Color.red.opacity(0.5))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .frame(height: 6)
            }

            if let lastRequest = metrics.lastRequestAt {
                Text("Last request: \(lastRequest.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 8))
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(.vertical, 4)
    }

    private func metricColumn(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(color)
        }
    }

    private func latencyColumn(label: String, value: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
            Text(String(format: "%.0fms", value * 1000))
                .font(.caption2.monospacedDigit())
        }
    }
}

#Preview {
    NavigationStack {
        SDKConnectorMetricsView()
    }
}
