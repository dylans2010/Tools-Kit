import SwiftUI

struct ConnectorRetryPolicyEditorView: View {
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @State private var selectedConnector: UUID?

    // Policy settings
    @State private var maxRetries = 3
    @State private var backoffInterval = 2.0 // seconds
    @State private var exponentialBackoff = true
    @State private var jitterEnabled = true

    var body: some View {
        List {
            Section("Target Connector") {
                Picker("Connector", selection: $selectedConnector) {
                    Text("Default (Global Policy)").tag(Optional<UUID>.none)
                    ForEach(connectorManager.connectors, id: \.id) { conn in
                        Text(conn.name).tag(Optional(conn.id))
                    }
                }
            }

            Section("Retry Constraints") {
                Stepper("Max Retry Attempts: \(maxRetries)", value: $maxRetries, in: 0...10)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Base Backoff Interval")
                        Spacer()
                        Text("\(String(format: "%.1f", backoffInterval))s").bold()
                    }
                    Slider(value: $backoffInterval, in: 0.5...10)
                }
            }

            Section("Backoff Strategy") {
                Toggle("Exponential Backoff", isOn: $exponentialBackoff)
                Toggle("Enable Jitter (Anti-Thundering Herd)", isOn: $jitterEnabled)
            }

            Section {
                Button(action: savePolicy) {
                    Text("Save Retry Policy")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Retry Policy")
    }

    private func savePolicy() {
        let target = selectedConnector?.uuidString ?? "Global"
        SDKLogStore.shared.log("Updated retry policy for \(target)", source: "RetryPolicyEditor", level: .info)
    }
}
