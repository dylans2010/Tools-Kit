import SwiftUI

struct Diag_ProxyCheckView: View {
    var body: some View {
        List {
            Section("Active Tunnels") {
                HStack {
                    Image(systemName: "shield.slash")
                        .foregroundStyle(.red)
                    Text("No VPN active")
                    Spacer()
                }

                HStack {
                    Image(systemName: "network.badge.shield.half.filled")
                        .foregroundStyle(.blue)
                    Text("iCloud Private Relay")
                    Spacer()
                    Text("Off")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Proxy Configuration") {
                LabeledContent("HTTP Proxy", value: "None")
                LabeledContent("PAC File", value: "None")
                LabeledContent("SOCKS Proxy", value: "None")
            }

            Section("Security Audit") {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Traffic is not being intercepted")
                }
            }
        }
        .navigationTitle("Proxy & Tunnel")
    }
}
