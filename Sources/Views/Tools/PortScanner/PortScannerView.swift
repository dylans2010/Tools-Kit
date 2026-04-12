import SwiftUI

struct PortScannerTool: Tool {
    let name = "Port Scanner"
    let icon = "network.badge.shield.half.filled"
    let category = ToolCategory.network
    let complexity = ToolComplexity.advanced
    let description = "Scan common ports on a host to check which services are accessible"
    let requiresAPI = false
    var view: AnyView { AnyView(PortScannerView()) }
}

struct PortScannerView: View {
    @StateObject private var backend = PortScannerBackend()

    var body: some View {
        ToolDetailView(tool: PortScannerTool()) {
            VStack(spacing: 16) {
                inputSection
                if !backend.results.isEmpty { resultsSection }
            }
        }
        .navigationTitle("Port Scanner")
    }

    private var inputSection: some View {
        ToolInputSection("Host") {
            VStack(spacing: 10) {
                TextField("scanme.nmap.org", text: $backend.host)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                HStack {
                    Button(backend.isScanning ? "Cancel" : "Scan \(PortScannerBackend.commonPorts.count) Ports") {
                        backend.isScanning ? backend.cancel() : backend.scan()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(backend.isScanning ? .red : .blue)

                    if backend.isScanning {
                        Spacer()
                        ProgressView(value: backend.progress)
                            .progressViewStyle(.linear)
                            .frame(maxWidth: 120)
                        Text("\(Int(backend.progress * 100))%")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }

    private var resultsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Label("\(backend.openCount) open", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green).font(.subheadline.bold())
                Spacer()
                Text("\(backend.results.count) ports scanned")
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(.horizontal)

            ToolInputSection("Results") {
                ForEach(backend.results) { result in
                    portRow(result)
                    Divider()
                }
            }
        }
    }

    private func portRow(_ result: PortResult) -> some View {
        HStack {
            Circle()
                .fill(statusColor(result.status))
                .frame(width: 10, height: 10)
            Text("\(result.port)").font(.system(.subheadline, design: .monospaced)).frame(width: 48, alignment: .leading)
            Text(result.service).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(statusText(result.status))
                .font(.caption.bold())
                .foregroundColor(statusColor(result.status))
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private func statusColor(_ status: PortResult.Status) -> Color {
        switch status {
        case .open: return .green
        case .closed: return .red
        case .timeout: return .orange
        case .pending: return .gray
        }
    }

    private func statusText(_ status: PortResult.Status) -> String {
        switch status {
        case .open: return "OPEN"
        case .closed: return "CLOSED"
        case .timeout: return "TIMEOUT"
        case .pending: return "–"
        }
    }
}
