import SwiftUI

struct SDKControlCenterView: View {
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared
    @State private var systemHealth = 0.98

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // System Health Overview
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("System Health", systemImage: "heart.text.square.fill")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(systemHealth * 100))%")
                            .font(.system(.title3, design: .monospaced))
                            .bold()
                            .foregroundStyle(systemHealth > 0.9 ? .green : .orange)
                    }

                    ProgressView(value: systemHealth)
                        .tint(systemHealth > 0.9 ? .green : .orange)

                    Text("SDK Execution Core is stable and connected to Workspace systems.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // Active Execution Monitoring
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Active Projects", systemImage: "cpu.fill")
                            .font(.headline)
                        Spacer()
                        Text("\(runtime.activeProjects.count)")
                            .bold()
                    }

                    if runtime.activeProjects.isEmpty {
                        ContentUnavailableView("No projects running", systemImage: "play.slash", description: Text("Start a project from the build tab."))
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

                // Runtime Metrics
                VStack(alignment: .leading, spacing: 12) {
                    Label("Runtime Load", systemImage: "chart.bar.fill")
                        .font(.headline)

                    HStack(spacing: 20) {
                        MetricCard(title: "Latency", value: "12ms", icon: "timer")
                        MetricCard(title: "Mem Use", value: "45MB", icon: "memorychip")
                        MetricCard(title: "TPS", value: "240", icon: "bolt.fill")
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // NoSandbox Toggle (Duplicate for visibility)
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
