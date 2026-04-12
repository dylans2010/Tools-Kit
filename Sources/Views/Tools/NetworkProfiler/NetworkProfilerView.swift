import SwiftUI

struct NetworkProfilerTool: Tool {
    let name = "Network Profiler"
    let icon = "waveform.path.ecg"
    let category = ToolCategory.network
    let complexity = ToolComplexity.advanced
    let description = "Monitor real-time latency, jitter, and request success rates over time"
    let requiresAPI = false
    var view: AnyView { AnyView(NetworkProfilerView()) }
}

struct NetworkProfilerView: View {
    @StateObject private var backend = NetworkProfilerBackend()

    var body: some View {
        ToolDetailView(tool: NetworkProfilerTool()) {
            VStack(spacing: 16) {
                configSection
                metricsSection
                historySection
            }
        }
        .navigationTitle("Network Profiler")
        .onDisappear { backend.stop() }
    }

    private var configSection: some View {
        ToolInputSection("Configuration") {
            VStack(spacing: 12) {
                HStack {
                    Text("Target URL").font(.subheadline)
                    Spacer()
                }
                TextField("https://www.apple.com", text: $backend.targetURL)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                HStack {
                    Text("Interval: \(Int(backend.intervalSeconds))s").font(.caption).foregroundColor(.secondary)
                    Slider(value: $backend.intervalSeconds, in: 2...30, step: 1)
                }
                HStack(spacing: 12) {
                    Button(backend.isRunning ? "Stop" : "Start") {
                        backend.isRunning ? backend.stop() : backend.start()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(backend.isRunning ? .red : .blue)
                    Button("Clear") { backend.clearHistory() }
                        .buttonStyle(.bordered)
                    Spacer()
                    Text(backend.statusMessage).font(.caption).foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }

    private var metricsSection: some View {
        HStack(spacing: 12) {
            metricCard(value: String(format: "%.0f ms", backend.averageLatency), label: "Avg Latency", icon: "clock.fill", color: .blue)
            metricCard(value: String(format: "%.0f ms", backend.jitter), label: "Jitter", icon: "waveform", color: .orange)
            metricCard(value: String(format: "%.0f%%", backend.successRate), label: "Success", icon: "checkmark.seal.fill", color: .green)
        }
        .padding(.horizontal)
    }

    private func metricCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(color).font(.title2)
            Text(value).font(.headline.monospacedDigit())
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var historySection: some View {
        ToolInputSection("Request History (\(backend.samples.count))") {
            if backend.samples.isEmpty {
                Text("No data yet. Start monitoring to collect samples.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(backend.recentSamples.reversed()) { sample in
                    HStack {
                        Circle()
                            .fill(sample.success ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(sample.timestamp, style: .time)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                        Spacer()
                        if sample.success {
                            Text(String(format: "%.0f ms", sample.latencyMs))
                                .font(.system(.caption, design: .monospaced))
                        } else {
                            Text("FAILED").font(.caption).foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    Divider().padding(.leading)
                }
            }
        }
    }
}
