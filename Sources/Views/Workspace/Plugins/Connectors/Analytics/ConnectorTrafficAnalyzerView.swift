import SwiftUI

struct ConnectorTrafficAnalyzerView: View {
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared

    var body: some View {
        List {
            Section("Connector Telemetry") {
                let metrics = telemetry.getMetrics()
                AnalyzerCard(title: "Total Traces", value: "\(metrics.totalTraces)", color: .blue)
                AnalyzerCard(title: "Success Rate", value: "\(metrics.totalTraces > 0 ? Int(Double(metrics.successCount) / Double(metrics.totalTraces) * 100) : 100)%", color: .green)
                AnalyzerCard(title: "Avg Duration", value: "\(Int(metrics.averageDurationMs))ms", color: .orange)
            }

            Section("Active Connector Manifest") {
                if connectorManager.connectors.isEmpty {
                    Text("No connectors registered").foregroundStyle(.secondary)
                } else {
                    ForEach(connectorManager.connectors, id: \.id) { connector in
                        HStack {
                            Label(connector.name, systemImage: "cable.connector")
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(connector.isConnected ? "Connected" : "Disconnected")
                                    .font(.caption2.bold())
                                    .foregroundStyle(connector.isConnected ? .green : .red)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Traffic Analyzer")
    }
}

private struct AnalyzerCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Label(title, systemImage: "waveform.path.ecg")
                .font(.subheadline)
            Spacer()
            Text(value).font(.headline.bold()).foregroundStyle(color)
        }
        .padding(.vertical, 4)
    }
}
