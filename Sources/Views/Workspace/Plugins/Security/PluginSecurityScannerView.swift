import SwiftUI

struct PluginSecurityScannerView: View {
    @StateObject private var manager = SDKPluginManager.shared
    @State private var scanResults: [PluginScanResult] = []
    @State private var isScanning = false

    struct PluginScanResult: Identifiable {
        let id = UUID()
        let pluginName: String
        let riskLevel: RiskLevel
        let findings: [String]

        enum RiskLevel: String {
            case low = "Low", medium = "Medium", high = "High", critical = "Critical"
            var color: Color {
                switch self {
                case .low: return .green
                case .medium: return .yellow
                case .high: return .orange
                case .critical: return .red
                }
            }
        }
    }

    var body: some View {
        List {
            Section {
                Button(action: runScan) {
                    HStack {
                        Label(isScanning ? "Scanning..." : "Run Security Scan", systemImage: "shield.viewfinder")
                        Spacer()
                        if isScanning { ProgressView() }
                    }
                }
                .disabled(isScanning)
            }

            if scanResults.isEmpty && !isScanning {
                ContentUnavailableView("No Scan Results", systemImage: "shield.checkered", description: Text("Run a scan to analyze installed plugins for security risks."))
            } else {
                ForEach(scanResults) { result in
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(result.pluginName).font(.headline)
                                Spacer()
                                Text(result.riskLevel.rawValue)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(result.riskLevel.color.opacity(0.15), in: Capsule())
                                    .foregroundStyle(result.riskLevel.color)
                            }

                            ForEach(result.findings, id: \.self) { finding in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(result.riskLevel.color)
                                    Text(finding)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Security Scanner")
    }

    private func runScan() {
        isScanning = true
        scanResults = []

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            await MainActor.run {
                for plugin in manager.plugins {
                    var findings: [String] = []
                    var risk: PluginScanResult.RiskLevel = .low

                    if plugin.permissions.contains(.all) {
                        findings.append("Requests unrestricted system access (Wildcard).")
                        risk = .critical
                    }

                    if plugin.permissions.count > 5 {
                        findings.append("High number of requested permissions (\(plugin.permissions.count)).")
                        if risk != .critical { risk = .high }
                    }

                    if plugin.automationHooks.count > 3 {
                        findings.append("Large number of background automation hooks.")
                        if risk == .low { risk = .medium }
                    }

                    if findings.isEmpty {
                        findings.append("No immediate risks identified.")
                    }

                    scanResults.append(PluginScanResult(pluginName: plugin.name, riskLevel: risk, findings: findings))
                }
                isScanning = false
            }
        }
    }
}
