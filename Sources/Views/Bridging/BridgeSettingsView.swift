import SwiftUI

struct BridgeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var connectionManager = BridgeConnectionManager.shared

    @AppStorage("bridge_auto_reconnect") private var autoReconnect = true
    @AppStorage("bridge_require_approval") private var requireApproval = true
    @AppStorage("bridge_block_unsafe") private var blockUnsafe = true
    @AppStorage("bridge_read_only") private var readOnlyMode = false
    @AppStorage("bridge_timeout") private var timeout = 30.0
    @AppStorage("bridge_debug_logs") private var debugLogs = false

    var body: some View {
        Form {
            Section {
                if let device = connectionManager.activeDevice {
                    LabeledContent("Host URL", value: device.hostURL.absoluteString)
                    LabeledContent("Port", value: "\(device.port)")
                    LabeledContent("Platform", value: device.platform.rawValue)
                } else {
                    Text("No active device selected")
                        .foregroundColor(.secondary)
                }

                Button("Test Connection") {
                    Task {
                        if let device = connectionManager.activeDevice {
                            _ = await BridgeService.shared.testConnection(host: device.hostURL, port: device.port)
                        }
                    }
                }
                .disabled(connectionManager.activeDevice == nil)
            } header: {
                Text("Current Connection")
            }

            Section {
                Toggle("Auto Reconnect", isOn: $autoReconnect)
                VStack(alignment: .leading) {
                    Text("Connection Timeout: \(Int(timeout))s")
                    Slider(value: $timeout, in: 1...60, step: 1)
                }
            } header: {
                Text("Behavior")
            }

            Section {
                Toggle("Require Command Approval", isOn: $requireApproval)
                Toggle("Block Unsafe Commands", isOn: $blockUnsafe)
                Toggle("Read-Only Mode", isOn: $readOnlyMode)
            } header: {
                Text("Security")
            }

            Section {
                Toggle("Enable Debug Logging", isOn: $debugLogs)
                NavigationLink("Troubleshooting Guide", destination: BridgeTroubleshootingView())
            } header: {
                Text("Advanced")
            }

            Section {
                Button(role: .destructive) {
                    // Logic to clear all saved hosts
                } label: {
                    Text("Clear All Saved Hosts")
                }
            }
        }
        .navigationTitle("Bridge Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}
