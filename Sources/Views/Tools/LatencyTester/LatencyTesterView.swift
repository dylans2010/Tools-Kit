import SwiftUI

struct LatencyTesterView: View {
    @StateObject private var backend = LatencyTesterBackend()
    @State private var pingCount: Int = 5

    var body: some View {
        Form {
            Section(header: Text("Configuration")) {
                HStack {
                    Text("Host")
                    Spacer()
                    TextField("e.g. google.com", text: $backend.host)
                        .multilineTextAlignment(.trailing)
                        .autocapitalization(.none)
                        .autocorrectionDisabled(true)
                        .keyboardType(.URL)
                }

                Stepper("Ping Count: \(pingCount)", value: $pingCount, in: 1...20)
            }

            Section {
                if backend.isRunning {
                    Button(role: .destructive, action: backend.stop) {
                        Label("Stop", systemImage: "stop.circle")
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    Button(action: { backend.start(count: pingCount) }) {
                        Label("Start Pinging", systemImage: "antenna.radiowaves.left.and.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(backend.host.isEmpty)
                }
            }

            if !backend.results.isEmpty {
                Section(header: Text("Average: \(String(format: "%.1f", backend.averageLatency)) ms")) {
                    ForEach(backend.results) { result in
                        HStack {
                            Text("#\(result.index)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 30, alignment: .leading)

                            if let ms = result.latencyMs {
                                Text(String(format: "%.1f ms", ms))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(latencyColor(ms))
                            } else {
                                Text("—")
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(result.status)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Latency Tester")
    }

    private func latencyColor(_ ms: Double) -> Color {
        if ms < 100 { return .green }
        if ms < 300 { return .yellow }
        return .red
    }
}

struct LatencyTesterTool: Tool {
    let name = "Latency Tester"
    let icon = "antenna.radiowaves.left.and.right"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Measure HTTP round-trip latency to any host"
    let requiresAPI = false
    var view: AnyView { AnyView(LatencyTesterView()) }
}
