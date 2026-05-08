import SwiftUI

struct SDKDebugView: View {
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared
    @StateObject private var logStore = SDKLogStore.shared
    @State private var isStepping = false

    var body: some View {
        List {
            Section {
                SDKModernCard(padding: 12) {
                    VStack(spacing: 12) {
                        HStack {
                            Label("Execution Mode", systemImage: "shield.fill")
                                .font(.subheadline.bold())
                            Spacer()
                            SDKStatusPill(
                                runtime.isNoSandboxModeEnabled ? "Unrestricted" : "Sandboxed",
                                color: runtime.isNoSandboxModeEnabled ? .sdkError : .sdkSuccess
                            )
                        }

                        Divider().opacity(0.3)

                        HStack {
                            debugMetric(label: "Active Projects", value: "\(runtime.activeProjects.count)", icon: "folder.fill")
                            debugMetric(label: "Active Traces", value: "\(telemetry.activeTraces.count)", icon: "waveform.path.ecg", color: telemetry.activeTraces.count > 0 ? .sdkWarning : .sdkSuccess)
                        }
                    }
                }
            } header: {
                SDKSectionHeader("Runtime Status", subtitle: "Live engine state and mode", systemImage: "cpu.fill")
            }

            Section {
                let metrics = telemetry.getMetrics()
                HStack(spacing: 12) {
                    SDKStatPill(label: "Executions", value: "\(metrics.totalTraces)", color: .blue)
                    SDKStatPill(label: "Success", value: "\(metrics.successCount)", color: .sdkSuccess)
                    SDKStatPill(label: "Failure", value: "\(metrics.failureCount)", color: .sdkError)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)

                LabeledContent("Average Latency") {
                    Text("\(String(format: "%.1f", metrics.averageDurationMs))ms")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            } header: {
                SDKSectionHeader("Performance Metrics", subtitle: "Trace analytics and timing", systemImage: "chart.bar.fill")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    systemRow(label: "Physical Memory", value: "\(ProcessInfo.processInfo.physicalMemory / 1024 / 1024 / 1024) GB", icon: "memorychip")
                    systemRow(label: "Active Processors", value: "\(ProcessInfo.processInfo.activeProcessorCount)", icon: "cpu")
                    systemRow(label: "System Uptime", value: "\(Int(ProcessInfo.processInfo.systemUptime / 3600))h \(Int(ProcessInfo.processInfo.systemUptime.truncatingRemainder(dividingBy: 3600) / 60))m", icon: "clock.fill")
                }
                .padding(.vertical, 4)
            } header: {
                SDKSectionHeader("Hardware & Process", subtitle: "Host environment resources", systemImage: "desktopcomputer")
            }

            Section {
                let errors = logStore.entries.filter { $0.level == .error }.prefix(5)
                if errors.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.sdkSuccess)
                        Text("No errors reported in recent logs").font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
                } else {
                    ForEach(Array(errors)) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.message)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.sdkError)
                                .lineLimit(2)
                            HStack {
                                Text(entry.source).bold()
                                Spacer()
                                Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                            }
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                SDKSectionHeader("Incident Log", subtitle: "Recent critical system errors", systemImage: "exclamationmark.octagon.fill")
            }

            Section {
                Button {
                    isStepping.toggle()
                    let msg = isStepping ? "Debug Trace Started" : "Debug Trace Stopped"
                    SDKLogStore.shared.log(msg, source: "SDKDebugView", level: .info)
                } label: {
                    Label(isStepping ? "Stop Runtime Trace" : "Start Runtime Trace", systemImage: isStepping ? "stop.circle.fill" : "play.circle.fill")
                        .frame(maxWidth: .infinity)
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(isStepping ? .sdkError : .blue)
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Runtime Debug")
    }

    private func debugMetric(label: String, value: String, icon: String, color: Color = .primary) -> some View {
        SDKStatPill(label: label, value: value, color: color, icon: icon)
    }

    private func systemRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}
