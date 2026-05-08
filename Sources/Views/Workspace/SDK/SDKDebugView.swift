import SwiftUI

struct SDKDebugView: View {
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared
    @StateObject private var logStore = SDKLogStore.shared
    @State private var isStepping = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SDKSectionHeader(title: "Runtime Debug", subtext: "Live inspection of the SDK kernel and processes.")

                SDKModernCard {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Execution Mode")
                            Spacer()
                            SDKStatusPill(status: runtime.isNoSandboxModeEnabled ? .error : .success, text: runtime.isNoSandboxModeEnabled ? "UNRESTRICTED" : "SANDBOXED")
                        }
                        LabeledContent("Active Projects", value: "\(runtime.activeProjects.count)")
                        LabeledContent("Active Traces", value: "\(telemetry.activeTraces.count)")
                    }
                }

                SDKSectionHeader(title: "Live Traces", subtext: "Currently executing SDK operations.")
                VStack(spacing: 12) {
                    let active = Array(telemetry.activeTraces.values)
                    if active.isEmpty {
                        SDKModernCard { Text("No active traces").sdkSubtext().frame(maxWidth: .infinity) }
                    } else {
                        ForEach(active, id: \.id) { trace in
                            SDKModernCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(trace.action)").font(.subheadline.bold())
                                        Text(trace.startTime.formatted(date: .omitted, time: .standard)).sdkSubtext()
                                    }
                                    Spacer()
                                    ProgressView().scaleEffect(0.8)
                                }
                            }
                        }
                    }
                }

                SDKSectionHeader(title: "Performance Metrics", subtext: "Resource consumption and timing.")
                SDKModernCard {
                    let metrics = telemetry.getMetrics()
                    VStack(spacing: 12) {
                        LabeledContent("Avg Duration", value: "\(String(format: "%.1f", metrics.averageDurationMs))ms")
                        LabeledContent("Total Runs", value: "\(metrics.totalTraces)")
                        LabeledContent("Memory Estimate", value: "\(ProcessInfo.processInfo.physicalMemory / 1024 / 1024) MB")
                        LabeledContent("System Uptime", value: "\(Int(ProcessInfo.processInfo.systemUptime / 3600))h")
                    }
                }

                SDKSectionHeader(title: "Recent Failures", subtext: "Critical errors from the log store.")
                VStack(spacing: 12) {
                    let errors = logStore.entries.filter { $0.level == .error }.prefix(5)
                    if errors.isEmpty {
                        SDKModernCard { Text("No critical errors").sdkSubtext().frame(maxWidth: .infinity) }
                    } else {
                        ForEach(Array(errors)) { entry in
                            SDKModernCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        SDKStatusPill(status: .error, text: "ERROR")
                                        Spacer()
                                        Text(entry.source).font(.caption2.monospaced()).foregroundStyle(.tertiary)
                                    }
                                    Text(entry.message).font(.system(.caption, design: .monospaced)).sdkErrorText()
                                }
                            }
                        }
                    }
                }

                Button(action: { isStepping.toggle() }) {
                    Label(isStepping ? "Stop Debug Trace" : "Start Debug Trace", systemImage: "ladybug.fill")
                        .frame(maxWidth: .infinity).bold()
                }
                .buttonStyle(.borderedProminent)
                .tint(isStepping ? .red : .accentColor)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Runtime Debug")
    }
}
