import SwiftUI
import Network

struct Diag_NetworkInterfacesView: View {
    @State private var interfaces: [InterfaceInfo] = []
    @State private var isRefreshing = false
    @State private var totalTX: UInt64 = 0
    @State private var totalRX: UInt64 = 0

    struct InterfaceInfo: Identifiable {
        let id = UUID()
        let name: String
        let address: String
        let family: String
        let flags: UInt32
        let isUp: Bool
        let isRunning: Bool
        let txBytes: UInt64
        let rxBytes: UInt64
    }

    var body: some View {
        Form {
            Section("Summary") {
                LabeledContent("Active Interfaces") {
                    Text("\(interfaces.filter(\.isUp).count)")
                        .foregroundStyle(.green)
                }
                LabeledContent("Total Interfaces") { Text("\(interfaces.count)") }
                LabeledContent("Total TX") { Text(formatBytes(totalTX)).monospacedDigit() }
                LabeledContent("Total RX") { Text(formatBytes(totalRX)).monospacedDigit() }
            }

            Section("WiFi (en0)") {
                let wifi = interfaces.filter { $0.name == "en0" }
                if wifi.isEmpty {
                    Text("No WiFi interface")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(wifi) { iface in
                        interfaceRow(iface)
                    }
                }
            }

            Section("Cellular (pdp_ip)") {
                let cellular = interfaces.filter { $0.name.hasPrefix("pdp_ip") }
                if cellular.isEmpty {
                    Text("No cellular interface")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(cellular) { iface in
                        interfaceRow(iface)
                    }
                }
            }

            Section("VPN / Tunnel") {
                let vpn = interfaces.filter { $0.name.hasPrefix("utun") || $0.name.hasPrefix("ipsec") }
                if vpn.isEmpty {
                    Text("No VPN interfaces")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(vpn) { iface in
                        interfaceRow(iface)
                    }
                }
            }

            Section("Loopback & Other") {
                let other = interfaces.filter { $0.name.hasPrefix("lo") || (!$0.name.hasPrefix("en") && !$0.name.hasPrefix("pdp") && !$0.name.hasPrefix("utun") && !$0.name.hasPrefix("ipsec")) }
                ForEach(other) { iface in
                    interfaceRow(iface)
                }
            }

            Section {
                Button {
                    loadInterfaces()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                }
            }
        }
        .navigationTitle("Network Interfaces")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadInterfaces() }
    }

    @ViewBuilder
    private func interfaceRow(_ iface: InterfaceInfo) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(iface.isUp ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(iface.name)
                    .font(.subheadline.weight(.medium))
                Text(iface.family)
                    .font(.caption)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
                Spacer()
                Text(iface.isUp ? "UP" : "DOWN")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(iface.isUp ? .green : .red)
            }
            Text(iface.address)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            if iface.txBytes > 0 || iface.rxBytes > 0 {
                HStack {
                    Text("TX: \(formatBytes(iface.txBytes))")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text("RX: \(formatBytes(iface.rxBytes))")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func loadInterfaces() {
        isRefreshing = true
        var result: [InterfaceInfo] = []
        totalTX = 0
        totalRX = 0

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else {
            isRefreshing = false
            return
        }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let addr = ptr {
            let name = String(cString: addr.pointee.ifa_name)
            let flags = addr.pointee.ifa_flags
            let isUp = (flags & UInt32(IFF_UP)) != 0
            let isRunning = (flags & UInt32(IFF_RUNNING)) != 0

            if let sa = addr.pointee.ifa_addr {
                let family = sa.pointee.sa_family
                if family == sa_family_t(AF_INET) || family == sa_family_t(AF_INET6) {
                    var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(sa, socklen_t(sa.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
                    let address = String(cString: host)
                    let familyStr = family == sa_family_t(AF_INET) ? "IPv4" : "IPv6"

                    var tx: UInt64 = 0
                    var rx: UInt64 = 0
                    if let data = addr.pointee.ifa_data {
                        let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                        tx = UInt64(networkData.ifi_obytes)
                        rx = UInt64(networkData.ifi_ibytes)
                        totalTX += tx
                        totalRX += rx
                    }

                    result.append(InterfaceInfo(name: name, address: address, family: familyStr, flags: flags, isUp: isUp, isRunning: isRunning, txBytes: tx, rxBytes: rx))
                }
            }
            ptr = addr.pointee.ifa_next
        }

        interfaces = result
        isRefreshing = false
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
