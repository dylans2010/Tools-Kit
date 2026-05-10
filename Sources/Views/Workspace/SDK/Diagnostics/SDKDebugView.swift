

import SwiftUI

struct SDKDebugView: View {
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared
    @StateObject private var logStore = SDKLogStore.shared
    @State private var isStepping = false

    var body: some View {
        List {
            Section("Runtime Profile") {
                LabeledContent("Execution Mode") {
                    Text(runtime.isNoSandboxModeEnabled ? "Unrestricted" : "Sandboxed")
                        .foregroundStyle(runtime.isNoSandboxModeEnabled ? Color.red : Color.green)
                        .bold()
                }
                LabeledContent("Active Projects", value: "\(runtime.activeProjects.count)")
                LabeledContent("Active Traces") {
                    Text("\(telemetry.activeTraces.count)")
                        .foregroundStyle(telemetry.activeTraces.count > 0 ? Color.orange : Color.secondary)
                        .bold()
                }
            }

            Section("Performance Analytics") {
                let metrics = telemetry.getMetrics()
                LabeledContent("Total Executions", value: "\(metrics.totalTraces)")
                LabeledContent("Average Latency", value: "\(Int(metrics.averageDurationMs))ms")
                LabeledContent("Success Count", value: "\(metrics.successCount)")
                    .foregroundStyle(.green)
                LabeledContent("Failure Count", value: "\(metrics.failureCount)")
                    .foregroundStyle(metrics.failureCount > 0 ? Color.red : Color.secondary)
            }

            Section("Host Environment") {
                LabeledContent("Physical Memory", value: "\(ProcessInfo.processInfo.physicalMemory / 1024 / 1024 / 1024) GB")
                LabeledContent("Active Processors", value: "\(ProcessInfo.processInfo.activeProcessorCount)")
                LabeledContent("System Uptime", value: "\(Int(ProcessInfo.processInfo.systemUptime / 3600))h \(Int(ProcessInfo.processInfo.systemUptime.truncatingRemainder(dividingBy: 3600) / 60))m")
            }

            Section("Incident Log") {
                let errors = logStore.entries.filter { $0.level == .error }.prefix(5)
                if errors.isEmpty {
                    Text("No system errors reported").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(Array(errors)) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.message).font(.caption.monospaced()).foregroundStyle(.red).lineLimit(2)
                            HStack {
                                Text(entry.source).bold()
                                Spacer()
                                Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                            }
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section {
                Button(role: isStepping ? .destructive : nil) {
                    isStepping.toggle()
                    let msg = isStepping ? "Debug Trace Started" : "Debug Trace Stopped"
                    SDKLogStore.shared.log(msg, source: "SDKDebugView", level: .info)
                } label: {
                    Label(isStepping ? "Stop Runtime Trace" : "Start Runtime Trace",
                          systemImage: isStepping ? "stop.circle.fill" : "play.circle.fill")
                        .bold()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Runtime Debug")
        .navigationBarTitleDisplayMode(.inline)
    }
}
