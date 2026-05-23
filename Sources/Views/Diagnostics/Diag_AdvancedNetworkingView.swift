import SwiftUI

struct Diag_AdvancedNetworkingView: View {
    @StateObject private var service = DiagnosticsService.shared
    @State private var dnsServers: [String] = []
    @State private var localIP: String = "Unknown"

    var body: some View {
        Form {
            Section("Local Network") {
                LabeledContent("Local IP", value: localIP)
                LabeledContent("Hostname", value: service.hostname)
            }

            Section("DNS Servers") {
                if dnsServers.isEmpty {
                    Text("No DNS servers detected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(dnsServers, id: \.self) { server in
                        Text(server).monospacedDigit()
                    }
                }
            }

            Section("Interface Identifiers") {
                LabeledContent("WiFi Interface", value: "en0")
                LabeledContent("Cellular Interface", value: "pdp_ip0")
            }

            Section {
                Button("Refresh Info") {
                    refreshInfo()
                }
            }
        }
        .navigationTitle("Advanced Networking")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshInfo()
        }
    }

    private func refreshInfo() {
        dnsServers = service.getDNSServers()
        localIP = service.getLocalIPAddress() ?? "Unavailable"
    }
}
