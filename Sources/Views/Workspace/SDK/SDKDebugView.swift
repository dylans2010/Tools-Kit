import SwiftUI

struct SDKDebugView: View {
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared
    @StateObject private var logStore = SDKLogStore.shared
    @State private var isStepping = false

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Execution Mode")
                    Spacer()
                    Text(runtime.isNoSandboxModeEnabled ? "Unrestricted" : "Sandboxed")
                        .foregroundStyle(runtime.isNoSandboxModeEnabled ? .red : .green)
                }
                HStack {
                    Text("Active Projects")
                    Spacer()
                    Text("\(runtime.activeProjects.count)")
                }
                HStack {
                    Text("Active Traces")
                    Spacer()
                    Text("\(telemetry.activeTraces.count)")
                        .foregroundStyle(telemetry.activeTraces.count > 0 ? .orange : .green)
                }
            } header: {
                Text("Runtime Status")
            }

            Section {
                let metrics = telemetry.getMetrics()
                HStack {
                    Text("Total Executions")
                    Spacer()
                    Text("\(metrics.totalTraces)")
                        .font(.system(.body, design: .monospaced))
                }
                HStack {
                    Text("Success / Failure")
                    Spacer()
                    Text("\(metrics.successCount) / \(metrics.failureCount)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(metrics.failureCount > 0 ? .orange : .primary)
                }
                HStack {
                    Text("Avg Duration")
                    Spacer()
                    Text("\(String(format: "%.1f", metrics.averageDurationMs))ms")
                        .font(.system(.body, design: .monospaced))
                }
            } header: {
                Text("Execution Metrics")
            }

            Section {
                HStack {
                    Text("Physical Memory")
                    Spacer()
                    Text("\(ProcessInfo.processInfo.physicalMemory / 1024 / 1024) MB")
                        .font(.system(.body, design: .monospaced))
                }
                HStack {
                    Text("Active Processors")
                    Spacer()
                    Text("\(ProcessInfo.processInfo.activeProcessorCount)")
                        .font(.system(.body, design: .monospaced))
                }
                HStack {
                    Text("Uptime")
                    Spacer()
                    Text("\(Int(ProcessInfo.processInfo.systemUptime / 3600))h \(Int(ProcessInfo.processInfo.systemUptime.truncatingRemainder(dividingBy: 3600) / 60))m")
                        .font(.system(.body, design: .monospaced))
                }
            } header: {
                Text("Memory & Process")
            }

            Section {
                let errors = logStore.entries.filter { $0.level == .error }.prefix(10)
                if errors.isEmpty {
                    Text("No Errors Recorded").foregroundStyle(.secondary).font(.caption)
                } else {
                    ForEach(Array(errors)) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.message).font(.system(size: 11, design: .monospaced)).foregroundStyle(.red)
                            Text("[\(entry.source)] \(entry.timestamp.formatted(date: .omitted, time: .shortened))")
                                .font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Recent Errors")
            }

            Section {
                ForEach(Thread.callStackSymbols.prefix(5), id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 8, design: .monospaced))
                        .lineLimit(1)
                }
            } header: {
                Text("Thread Trace")
            }

            Section {
                Button(isStepping ? "Stop Debug" : "Start Trace") {
                    isStepping.toggle()
                    if isStepping {
                        SDKLogStore.shared.log("Debug trace started", source: "SDKDebugView", level: .info)
                    } else {
                        SDKLogStore.shared.log("Debug trace stopped", source: "SDKDebugView", level: .info)
                    }
                }
                .foregroundStyle(isStepping ? .red : .blue)
            }
        }
        .navigationTitle("SDK Runtime Debug")
    }
}
