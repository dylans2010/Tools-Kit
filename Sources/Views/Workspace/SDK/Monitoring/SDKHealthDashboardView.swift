// ToolsKit — SDKHealthDashboardView.swift
// SDK Expansion — Phase 3

import SwiftUI

struct SDKHealthDashboardView: View {
    @StateObject private var healthMonitor = SDKHealthMonitor.shared
    @State private var isRefreshing = false

    var body: some View {
        List {
            overallStatusSection
            componentsSection
            actionsSection
            if let report = healthMonitor.lastReport {
                reportSection(report)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Health Dashboard")
        .refreshable { await refresh() }
        .task { await refresh() }
    }

    private var overallStatusSection: some View {
        Section("Overall Status") {
            HStack {
                statusIcon(for: healthMonitor.overallStatus)
                VStack(alignment: .leading, spacing: 2) {
                    Text(healthMonitor.overallStatus.rawValue.capitalized)
                        .font(.headline)
                    Text("Checks Performed: \(healthMonitor.checkCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if healthMonitor.isMonitoring {
                    Label("Monitoring", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private var componentsSection: some View {
        Section("Components") {
            if healthMonitor.componentStatuses.isEmpty {
                ContentUnavailableView(
                    "No Health Data",
                    systemImage: "heart.text.square",
                    description: Text("Run a health check to see component status.")
                )
            } else {
                ForEach(healthMonitor.componentStatuses) { component in
                    HStack {
                        statusIcon(for: component.status)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(component.name)
                                .font(.subheadline.bold())
                            if !component.message.isEmpty {
                                Text(component.message)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(component.status.rawValue)
                                .font(.caption.bold())
                                .foregroundStyle(statusColor(for: component.status))
                            Text(String(format: "%.0fms", component.latency * 1000))
                                .font(.caption2.monospaced())
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            Button {
                Task { await refresh() }
            } label: {
                Label(isRefreshing ? "Checking..." : "Run Health Check", systemImage: "heart.text.square")
            }
            .disabled(isRefreshing)

            Button {
                if healthMonitor.isMonitoring {
                    healthMonitor.stopMonitoring()
                } else {
                    healthMonitor.startMonitoring()
                }
            } label: {
                Label(
                    healthMonitor.isMonitoring ? "Stop Monitoring" : "Start Monitoring",
                    systemImage: healthMonitor.isMonitoring ? "stop.circle" : "play.circle"
                )
            }
        }
    }

    private func reportSection(_ report: SDKHealthReport) -> some View {
        Section("Last Report") {
            LabeledContent("Timestamp", value: report.timestamp.formatted(date: .abbreviated, time: .standard))
            LabeledContent("Duration", value: String(format: "%.0fms", report.checkDuration * 1000))
            LabeledContent("Components", value: "\(report.components.count)")
            let healthy = report.components.filter { $0.status == .healthy }.count
            LabeledContent("Healthy", value: "\(healthy)/\(report.components.count)")
        }
    }

    private func statusIcon(for status: SDKHealthStatus) -> some View {
        Image(systemName: statusSystemImage(for: status))
            .foregroundStyle(statusColor(for: status))
            .font(.title3)
            .frame(width: 28)
    }

    private func statusSystemImage(for status: SDKHealthStatus) -> String {
        switch status {
        case .healthy: return "checkmark.circle.fill"
        case .degraded: return "exclamationmark.triangle.fill"
        case .unhealthy: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    private func statusColor(for status: SDKHealthStatus) -> Color {
        switch status {
        case .healthy: return .green
        case .degraded: return .orange
        case .unhealthy: return .red
        case .unknown: return .gray
        }
    }

    private func refresh() async {
        isRefreshing = true
        _ = await healthMonitor.checkHealth()
        isRefreshing = false
    }
}

#Preview {
    NavigationStack {
        SDKHealthDashboardView()
    }
}
