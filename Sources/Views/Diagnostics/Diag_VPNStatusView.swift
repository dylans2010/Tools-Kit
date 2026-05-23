import SwiftUI
import Network

struct Diag_VPNStatusView: View {
    @State private var vpnConnected = false
    @State private var interfaces: [(String, String)] = []
    @State private var dnsServers: String = "Checking..."

    var body: some View {
        Form {
            Section("VPN Status") {
                VStack(spacing: 12) {
                    Image(systemName: vpnConnected ? "lock.shield.fill" : "lock.shield")
                        .font(.system(size: 48))
                        .foregroundStyle(vpnConnected ? .green : .secondary)
                    Text(vpnConnected ? "VPN Active" : "No VPN Detected")
                        .font(.headline)
                    Text(vpnConnected ? "Traffic is being routed through a VPN" : "Direct connection to network")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Network Interfaces") {
                if interfaces.isEmpty {
                    Text("No active interfaces")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(interfaces, id: \.0) { iface in
                        LabeledContent(iface.0) {
                            Text(iface.1)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("DNS") {
                Text(dnsServers)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Refresh") { checkVPN() }
            }
        }
        .navigationTitle("VPN Status")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkVPN() }
    }

    private func checkVPN() {
        var ifaceList: [(String, String)] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        var hasVPN = false

        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while let addr = ptr {
                let name = String(cString: addr.pointee.ifa_name)
                if name.hasPrefix("utun") || name.hasPrefix("ipsec") || name.hasPrefix("ppp") {
                    hasVPN = true
                }
                if addr.pointee.ifa_addr?.pointee.sa_family == UInt8(AF_INET) {
                    ifaceList.append((name, "IPv4"))
                } else if addr.pointee.ifa_addr?.pointee.sa_family == UInt8(AF_INET6) {
                    if !ifaceList.contains(where: { $0.0 == name }) {
                        ifaceList.append((name, "IPv6"))
                    }
                }
                ptr = addr.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        interfaces = ifaceList
        vpnConnected = hasVPN
        dnsServers = "System configured DNS"
    }
}
