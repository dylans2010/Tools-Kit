import SwiftUI

struct SDKControlCenterView: View {
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared
    @StateObject private var backgroundEngine = SDKBackgroundEngine.shared
    @StateObject private var realtimeSync = SDKRealtimeSync.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("System Health", systemImage: "heart.text.square.fill")
                            .font(.headline)
                        Spacer()
                        let healthPercent = computeHealthPercent()
                        Text("\(healthPercent)%")
                            .font(.system(.title3, design: .monospaced))
                            .bold()
                            .foregroundStyle(healthPercent > 90 ? .green : .orange)
                    }

                    ProgressView(value: Double(computeHealthPercent()) / 100.0)
                        .tint(computeHealthPercent() > 90 ? .green : .orange)

                    VStack(alignment: .leading, spacing: 4) {
                        healthRow("Connectors", healthy: backgroundEngine.systemHealth.connectorReachability)
                        healthRow("Plugins", healthy: backgroundEngine.systemHealth.pluginSandboxStatus)
                        healthRow("Storage", healthy: backgroundEngine.systemHealth.coreDataHealth)
                    }

                    Text("Last Checked: \(backgroundEngine.systemHealth.lastCheck, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Active Projects", systemImage: "cpu.fill")
                            .font(.headline)
                        Spacer()
                        Text("\(runtime.activeProjects.count)")
                            .bold()
                    }

                    if runtime.activeProjects.isEmpty {
                        ContentUnavailableView("No Projects Running", systemImage: "play.slash", description: Text("Start a project from the Build tab."))
                            .frame(height: 100)
                    } else {
                        ForEach(runtime.activeProjects) { project in
                            HStack {
                                Circle().fill(.green).frame(width: 8, height: 8)
                                Text(project.name)
                                Spacer()
                                Button("Stop") { runtime.stopProject(id: project.id) }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Runtime Metrics", systemImage: "chart.bar.fill")
                        .font(.headline)

                    let metrics = telemetry.getMetrics()
                    HStack(spacing: 20) {
                        MetricCard(title: "Latency", value: "\(String(format: "%.0f", metrics.averageDurationMs))ms", icon: "timer")
                        MetricCard(title: "Traces", value: "\(metrics.totalTraces)", icon: "memorychip")
                        MetricCard(title: "Success", value: "\(metrics.successCount)", icon: "bolt.fill")
                    }

                    if metrics.failureCount > 0 {
                        Text("\(metrics.failureCount) Failures Detected")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Realtime Sync", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.headline)

                    HStack {
                        Circle().fill(realtimeSync.isConnected ? .green : .gray).frame(width: 8, height: 8)
                        Text(realtimeSync.isConnected ? "Connected" : "Idle")
                            .font(.caption)
                        Spacer()
                        Text("\(realtimeSync.activeChannels.count) Channels")
                            .font(.caption).foregroundStyle(.secondary)
                    }

                    if !realtimeSync.activeChannels.isEmpty {
                        ForEach(Array(realtimeSync.activeChannels).sorted(), id: \.self) { channel in
                            Text(channel)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Connectors", systemImage: "link")
                        .font(.headline)

                    if connectorManager.connectors.isEmpty {
                        Text("No Connectors Registered").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(connectorManager.connectors, id: \.id) { connector in
                            HStack {
                                Circle()
                                    .fill(connector.status == .connected ? .green : .gray)
                                    .frame(width: 8, height: 8)
                                Text(connector.name).font(.caption)
                                Spacer()
                                Text(connector.status.rawValue).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                VStack {
                    Toggle(isOn: $runtime.isNoSandboxModeEnabled) {
                        VStack(alignment: .leading) {
                            Text("No-Sandbox Mode")
                                .bold()
                            Text("Bypass execution restrictions (Developer Only)")
                                .font(.caption)
                        }
                    }
                    .tint(.red)
                    .onChange(of: runtime.isNoSandboxModeEnabled) { enabled in
                        if enabled {
                            SDKLogStore.shared.log("No Sandbox mode ENABLED via Control Center", source: "SDKControlCenterView", level: .warning)
                        }
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))
            }
            .padding()
        }
        .navigationTitle("SDK Control Center")
    }

    private func computeHealthPercent() -> Int {
        let health = backgroundEngine.systemHealth
        var score = 100
        if !health.connectorReachability { score -= 30 }
        if !health.pluginSandboxStatus { score -= 20 }
        if !health.coreDataHealth { score -= 40 }
        return max(0, score)
    }

    private func healthRow(_ label: String, healthy: Bool) -> some View {
        HStack {
            Circle().fill(healthy ? .green : .red).frame(width: 8, height: 8)
            Text(label).font(.caption)
            Spacer()
            Text(healthy ? "Healthy" : "Degraded")
                .font(.caption)
                .foregroundStyle(healthy ? .green : .red)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .monospaced()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
