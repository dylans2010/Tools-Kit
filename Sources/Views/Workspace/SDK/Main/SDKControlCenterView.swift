

import SwiftUI

struct SDKControlCenterView: View {
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared
    @StateObject private var backgroundEngine = SDKBackgroundEngine.shared
    @StateObject private var realtimeSync = SDKRealtimeSync.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared

    var body: some View {
        Form {
            healthSection
            activeProjectsSection
            runtimeMetricsSection
            syncSection
            connectorsSection
            developerSection
        }
        .navigationTitle("Control Center")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var healthSection: some View {
        Section {
            LabeledContent(content: {
                let healthPercent = computeHealthPercent()
                Text("\(healthPercent)%")
                    .font(.headline.monospaced())
                    .foregroundStyle(healthPercent > 90 ? Color.green : Color.orange)
            }, label: {
                Label("System Health", systemImage: "heart.text.square")
            })

            HealthRow(label: "Connectors", healthy: backgroundEngine.systemHealth.connectorReachability)
            HealthRow(label: "Plugins", healthy: backgroundEngine.systemHealth.pluginSandboxStatus)
            HealthRow(label: "Storage", healthy: backgroundEngine.systemHealth.coreDataHealth)

            Text("Last Checked: \(backgroundEngine.systemHealth.lastCheck, style: .relative) ago")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } header: {
            Text("Integrity")
        }
    }

    private var activeProjectsSection: some View {
        Section {
            if runtime.activeProjects.isEmpty {
                ContentUnavailableView("No Projects Running", systemImage: "play.slash", description: Text("Start a project from the Build tab."))
                    .frame(height: 120)
            } else {
                ForEach(runtime.activeProjects) { project in
                    HStack {
                        Label(project.name, systemImage: "cpu")
                            .symbolEffect(.pulse, options: .repeating)
                        Spacer()
                        Button("Stop") { runtime.stopProject(id: project.id) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(.red)
                    }
                }
            }
        } header: {
            Text("Execution")
        }
    }

    private var runtimeMetricsSection: some View {
        Section {
            let metrics = telemetry.getMetrics()
            LabeledContent("Avg Latency", value: "\(Int(metrics.averageDurationMs))ms")
            LabeledContent("Total Traces", value: "\(metrics.totalTraces)")
            LabeledContent("Success Count", value: "\(metrics.successCount)")

            if metrics.failureCount > 0 {
                Label("\(metrics.failureCount) Failures", systemImage: "exclamationmark.octagon")
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Performance")
        }
    }

    private var syncSection: some View {
        Section {
            LabeledContent(content: {
                Label(realtimeSync.isConnected ? "Connected" : "Idle",
                      systemImage: realtimeSync.isConnected ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                    .foregroundStyle(realtimeSync.isConnected ? Color.green : Color.secondary)
            }, label: {
                Text("Status")
            })

            if !realtimeSync.activeChannels.isEmpty {
                ForEach(Array(realtimeSync.activeChannels).sorted(), id: \.self) { channel in
                    Text(channel)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Realtime Sync")
        }
    }

    private var connectorsSection: some View {
        Section {
            if connectorManager.connectors.isEmpty {
                Text("No Connectors Registered").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(connectorManager.connectors, id: \.id) { connector in
                    LabeledContent(content: {
                        Text(connector.status.rawValue.capitalized)
                            .foregroundStyle(connector.status == .connected ? Color.green : Color.secondary)
                    }, label: {
                        Text(connector.name)
                    })
                }
            }
        } header: {
            Text("External Connectivity")
        }
    }

    private var developerSection: some View {
        Section {
            Toggle(isOn: $runtime.isNoSandboxModeEnabled) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No-Sandbox Mode")
                        Text("Bypass execution restrictions")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "shield.slash")
                        .foregroundStyle(runtime.isNoSandboxModeEnabled ? Color.red : Color.secondary)
                }
            }
            .tint(.red)
        } header: {
            Text("Advanced")
        } footer: {
            Text("Enable only for internal testing. This bypasses all security boundaries.")
        }
    }

    // MARK: - Helpers

    private func computeHealthPercent() -> Int {
        let health = backgroundEngine.systemHealth
        var score = 100
        if !health.connectorReachability { score -= 30 }
        if !health.pluginSandboxStatus { score -= 20 }
        if !health.coreDataHealth { score -= 40 }
        return max(0, score)
    }
}

private struct HealthRow: View {
    let label: String
    let healthy: Bool

    var body: some View {
        LabeledContent(content: {
            Image(systemName: healthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(healthy ? Color.green : Color.red)
        }, label: {
            Text(label)
        })
    }
}
