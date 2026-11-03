import SwiftUI

struct NetIPv6InterfacesRow: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let family: String
    let isUp: Bool
    let tx: UInt64
    let rx: UInt64
}

private func diagNewLoadInterfacesNetIPv6Interfaces() -> [NetIPv6InterfacesRow] {
    var result: [NetIPv6InterfacesRow] = []
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return result }
    defer { freeifaddrs(ifaddr) }
    var ptr: UnsafeMutablePointer<ifaddrs>? = first
    while let addr = ptr {
        let name = String(cString: addr.pointee.ifa_name)
        let flags = addr.pointee.ifa_flags
        let isUp = (flags & UInt32(IFF_UP)) != 0
        if let sa = addr.pointee.ifa_addr {
            let family = sa.pointee.sa_family
            if family == sa_family_t(AF_INET) || family == sa_family_t(AF_INET6) {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(sa, socklen_t(sa.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
                let address = String(cString: host)
                var tx: UInt64 = 0
                var rx: UInt64 = 0
                if let data = addr.pointee.ifa_data {
                    let d = data.assumingMemoryBound(to: if_data.self).pointee
                    tx = UInt64(d.ifi_obytes); rx = UInt64(d.ifi_ibytes)
                }
                result.append(NetIPv6InterfacesRow(name: name, address: address, family: family == sa_family_t(AF_INET) ? "IPv4" : "IPv6", isUp: isUp, tx: tx, rx: rx))
            }
        }
        ptr = addr.pointee.ifa_next
    }
    return result
}

private func diagNewFmtBytesNetIPv6Interfaces(_ bytes: UInt64) -> String {
    let f = ByteCountFormatter(); f.countStyle = .binary; return f.string(fromByteCount: Int64(bytes))
}

struct Diag_NetIPv6InterfacesView: View {
    @State private var rows: [NetIPv6InterfacesRow] = []

    var body: some View {
        Form {
            Section("Interfaces (\(rows.count))") {
                if rows.isEmpty {
                    Text("No IPv6 interfaces found").foregroundStyle(.secondary)
                } else {
                    ForEach(rows) { r in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.name).font(.subheadline.weight(.medium))
                            Text("\(r.address) (\(r.family))").font(.caption).foregroundStyle(.secondary)
                            Text("Up: \(r.isUp ? "Yes" : "No")  TX: \(diagNewFmtBytesNetIPv6Interfaces(r.tx))  RX: \(diagNewFmtBytesNetIPv6Interfaces(r.rx))").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section { Button("Refresh") { load() } }
        }
        .navigationTitle("IPv6 Interfaces")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = diagNewLoadInterfacesNetIPv6Interfaces().filter { r.family == "IPv6" }
    }
}
