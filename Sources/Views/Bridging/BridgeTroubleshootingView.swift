import SwiftUI

struct BridgeTroubleshootingView: View {
    var body: some View {
        List {
            Section {
                TroubleshootingRow(
                    issue: "Host Unreachable",
                    explanation: "The mobile app cannot find the computer on the network.",
                    fixSteps: [
                        "Ensure both devices are on the same Wi-Fi network.",
                        "Check if the host computer's firewall is blocking the port.",
                        "Verify the host's IP address hasn't changed."
                    ]
                )

                TroubleshootingRow(
                    issue: "Connection Refused",
                    explanation: "The computer found but rejected the connection.",
                    fixSteps: [
                        "Ensure the Bridge Server is actually running on the host.",
                        "Check if another application is using the same port.",
                        "Restart the Bridge Server on the computer."
                    ]
                )
            } header: {
                Text("Connection Issues")
            }

            Section {
                TroubleshootingRow(
                    issue: "Invalid Pairing Code",
                    explanation: "The 6-digit code or QR token is incorrect.",
                    fixSteps: [
                        "Regenerate a new pairing code on the host computer.",
                        "Ensure the code hasn't expired (codes last 5 minutes).",
                        "Check for typos if entering manually."
                    ]
                )
            } header: {
                Text("Authentication Issues")
            }

            Section {
                TroubleshootingRow(
                    issue: "WebSocket Failure",
                    explanation: "The real-time stream was interrupted.",
                    fixSteps: [
                        "Check for VPN or proxy settings that might interfere with WebSockets.",
                        "Try disabling 'Low Data Mode' in your iOS Wi-Fi settings.",
                        "Use 'Test Connection' in Settings to verify basic HTTP reachability."
                    ]
                )
            } header: {
                Text("Streaming Issues")
            }
        }
        .navigationTitle("Troubleshooting")
    }
}

struct TroubleshootingRow: View {
    let issue: String
    let explanation: String
    let fixSteps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(issue)
                .font(.headline)
                .foregroundColor(.primary)

            Text(explanation)
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("How to fix:")
                    .font(.caption.bold())
                    .padding(.top, 4)

                ForEach(fixSteps, id: \.self) { step in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                        Text(step)
                            .font(.caption)
                    }
                }
            }

            Button("Retry Connection") {
                BridgeConnectionManager.shared.connect()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}
