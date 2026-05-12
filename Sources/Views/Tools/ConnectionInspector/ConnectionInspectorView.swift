import SwiftUI

struct ConnectionInspectorTool: Tool, Sendable {
    let name = "Connection Inspector"
    let icon = "waveform.path.ecg"
    let category = ToolCategory.network
    let complexity = ToolComplexity.advanced
    let description = "Measure latency, bandwidth, and request timing diagnostics"
    let requiresAPI = false
    var view: AnyView { AnyView(ConnectionInspectorView()) }
}

struct ConnectionInspectorView: View {
    @StateObject private var backend = ConnectionInspectorBackend()

    var body: some View {
        ToolDetailView(tool: ConnectionInspectorTool()) {
            VStack(spacing: 16) {
                Button {
                    Task { await backend.runInspection() }
                } label: {
                    if backend.isRunning {
                        HStack {
                            ProgressView().padding(.trailing, 6)
                            Text("Running Inspection…")
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                    } else {
                        Label("Run Inspection", systemImage: "play.fill")
                            .frame(maxWidth: .infinity).padding(.vertical, 4)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(backend.isRunning)

                if !backend.errorMessage.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        Text(backend.errorMessage).font(.caption)
                    }
                    .padding().frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1)).cornerRadius(12)
                }

                if !backend.pingResults.isEmpty {
                    pingSection
                }

                if backend.estimatedDownloadKbps > 0 {
                    bandwidthSection
                }

                if !backend.timingDiagnostics.isEmpty {
                    timingSection
                }
            }
        }
        .navigationTitle("Connection Inspector")
    }

    private var pingSection: some View {
        ToolInputSection("Endpoint Latency") {
            ForEach(backend.pingResults) { result in
                HStack {
                    Circle()
                        .fill(result.success ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(result.host).font(.subheadline).foregroundColor(.secondary)
                    Spacer()
                    if result.success {
                        Text(String(format: "%.0f ms", result.latencyMs))
                            .font(.subheadline.bold())
                            .foregroundColor(latencyColor(result.latencyMs))
                    } else {
                        Text("Timeout").font(.subheadline).foregroundColor(.red)
                    }
                }
                .padding()
                if result.id != backend.pingResults.last?.id { Divider().padding(.leading) }
            }
        }
    }

    private var bandwidthSection: some View {
        ToolInputSection("Bandwidth Estimate") {
            HStack {
                Image(systemName: "arrow.down.circle.fill").foregroundColor(.blue)
                Text("Download").foregroundColor(.secondary)
                Spacer()
                Text(formattedBandwidth(backend.estimatedDownloadKbps))
                    .font(.title3.bold()).foregroundColor(.blue)
            }
            .padding()
        }
    }

    private var timingSection: some View {
        ToolInputSection("Request Timing") {
            ForEach(backend.timingDiagnostics) { diag in
                HStack {
                    Text(diag.label).font(.subheadline).foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.1f ms", diag.durationMs))
                        .font(.subheadline.bold())
                }
                .padding()
                if diag.id != backend.timingDiagnostics.last?.id { Divider().padding(.leading) }
            }
        }
    }

    private func latencyColor(_ ms: Double) -> Color {
        if ms < 50 { return .green }
        if ms < 150 { return .orange }
        return .red
    }

    private func formattedBandwidth(_ kbps: Double) -> String {
        if kbps >= 1024 { return String(format: "%.1f Mbps", kbps / 1024) }
        return String(format: "%.0f Kbps", kbps)
    }
}
