// ToolsKit — SDKConnectorHealthView.swift
// SDK Expansion — Phase 4

import SwiftUI

struct SDKConnectorHealthView: View {
    @StateObject private var healthMonitor = SDKConnectorHealthMonitor.shared
    @State private var isChecking = false

    var body: some View {
        List {
            overallSection
            connectorsSection
            actionsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Connector Health")
        .refreshable { await runHealthCheck() }
        .task { await runHealthCheck() }
    }

    private var overallSection: some View {
        Section("Overall Health") {
            HStack {
                healthIcon(healthMonitor.overallHealth)
                VStack(alignment: .leading, spacing: 2) {
                    Text(healthMonitor.overallHealth.rawValue.capitalized)
                        .font(.headline)
                    if let lastCheck = healthMonitor.lastFullCheck {
                        Text("Last check: \(lastCheck.formatted(date: .omitted, time: .standard))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if healthMonitor.isMonitoring {
                    Label("Active", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private var connectorsSection: some View {
        Section("Connectors (\(healthMonitor.healthStatuses.count))") {
            if healthMonitor.healthStatuses.isEmpty {
                ContentUnavailableView(
                    "No Health Data",
                    systemImage: "cable.connector",
                    description: Text("Run a health check to see connector status.")
                )
            } else {
                ForEach(healthMonitor.healthStatuses) { status in
                    HStack {
                        healthIcon(status.status)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(status.connectorName)
                                .font(.subheadline.bold())
                            if let error = status.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .lineLimit(2)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(status.status.rawValue)
                                .font(.caption.bold())
                                .foregroundStyle(healthColor(status.status))
                            Text(String(format: "%.0fms", status.latency * 1000))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                            if status.consecutiveFailures > 0 {
                                Text("\(status.consecutiveFailures) failures")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            Button {
                Task { await runHealthCheck() }
            } label: {
                Label(isChecking ? "Checking..." : "Run Health Check", systemImage: "heart.text.square")
            }
            .disabled(isChecking)

            Button {
                if healthMonitor.isMonitoring {
                    healthMonitor.stopMonitoring()
                } else {
                    healthMonitor.startMonitoring()
                }
            } label: {
                Label(
                    healthMonitor.isMonitoring ? "Stop Monitoring" : "Start Auto-Monitor",
                    systemImage: healthMonitor.isMonitoring ? "stop.circle" : "play.circle"
                )
            }
        }
    }

    private func runHealthCheck() async {
        isChecking = true
        _ = await healthMonitor.checkAll()
        isChecking = false
    }

    private func healthIcon(_ status: SDKHealthStatus) -> some View {
        Image(systemName: healthSystemImage(status))
            .foregroundStyle(healthColor(status))
            .font(.title3)
            .frame(width: 28)
    }

    private func healthSystemImage(_ status: SDKHealthStatus) -> String {
        switch status {
        case .healthy: return "checkmark.circle.fill"
        case .degraded: return "exclamationmark.triangle.fill"
        case .unhealthy: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    private func healthColor(_ status: SDKHealthStatus) -> Color {
        switch status {
        case .healthy: return .green
        case .degraded: return .orange
        case .unhealthy: return .red
        case .unknown: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        SDKConnectorHealthView()
    }
}
