import SwiftUI
import SystemConfiguration
import Network

struct Diag_NetworkProxyView: View {
    @State private var proxySettings: [ProxySetting] = []
    @State private var isVPNActive = false
    @State private var networkType: String = "Checking..."
    @State private var dnsServers: [String] = []
    @State private var isRefreshing = false

    struct ProxySetting: Identifiable {
        let id = UUID()
        let type: String
        let host: String
        let port: Int
        let enabled: Bool
    }

    var body: some View {
        Form {
            Section("Proxy Status") {
                HStack {
                    Image(systemName: proxySettings.contains(where: \.enabled) ? "shield.lefthalf.filled" : "network")
                        .font(.title2)
                        .foregroundStyle(proxySettings.contains(where: \.enabled) ? .orange : .green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(proxySettings.contains(where: \.enabled) ? "Proxy Active" : "No Proxy")
                            .font(.headline)
                        Text(proxySettings.contains(where: \.enabled) ? "Traffic is being routed through a proxy" : "Direct connection")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Proxy Configuration") {
                if proxySettings.isEmpty {
                    Text("No proxy configuration detected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(proxySettings) { proxy in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(proxy.type)
                                    .font(.subheadline.weight(.medium))
                                if !proxy.host.isEmpty {
                                    Text("\(proxy.host):\(proxy.port)")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(proxy.enabled ? "Enabled" : "Disabled")
                                .font(.caption)
                                .foregroundStyle(proxy.enabled ? .green : .secondary)
                        }
                    }
                }
            }

            Section("VPN") {
                LabeledContent("VPN Active") {
                    Text(isVPNActive ? "Yes" : "No")
                        .foregroundStyle(isVPNActive ? .green : .secondary)
                }
                LabeledContent("Network Type") {
                    Text(networkType)
                }
            }

            Section("DNS Servers") {
                if dnsServers.isEmpty {
                    Text("Could not determine DNS servers")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(dnsServers, id: \.self) { server in
                        HStack {
                            Text(server)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            if server.starts(with: "8.8") || server.starts(with: "1.1") || server.starts(with: "9.9") {
                                Text("Public")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            } else if server.starts(with: "10.") || server.starts(with: "192.168") || server.starts(with: "172.") {
                                Text("Private")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }

            Section("Network Interfaces") {
                let interfaces = getActiveInterfaces()
                ForEach(interfaces, id: \.0) { name, addr in
                    HStack {
                        Text(name)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(addr)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button {
                    refreshAll()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(isRefreshing ? "Refreshing..." : "Refresh")
                    }
                }
                .disabled(isRefreshing)
            }
        }
        .navigationTitle("Network Proxy")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshAll() }
    }

    private func refreshAll() {
        isRefreshing = true
        loadProxySettings()
        checkVPN()
        loadDNS()
        checkNetworkType()
        isRefreshing = false
    }

    private func loadProxySettings() {
        guard let proxyDict = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] else {
            proxySettings = []
            return
        }

        var settings: [ProxySetting] = []

        // HTTP Proxy
        let httpEnabled = (proxyDict[kCFNetworkProxiesHTTPEnable as String] as? Int) == 1
        let httpHost = proxyDict[kCFNetworkProxiesHTTPProxy as String] as? String ?? ""
        let httpPort = proxyDict[kCFNetworkProxiesHTTPPort as String] as? Int ?? 0
        settings.append(ProxySetting(type: "HTTP", host: httpHost, port: httpPort, enabled: httpEnabled))

        // HTTPS Proxy
        let httpsEnabled = (proxyDict[kCFNetworkProxiesHTTPSEnable as String] as? Int) == 1
        let httpsHost = proxyDict[kCFNetworkProxiesHTTPSProxy as String] as? String ?? ""
        let httpsPort = proxyDict[kCFNetworkProxiesHTTPSPort as String] as? Int ?? 0
        settings.append(ProxySetting(type: "HTTPS", host: httpsHost, port: httpsPort, enabled: httpsEnabled))

        // SOCKS Proxy
        let socksEnabled = (proxyDict[kCFNetworkProxiesSOCKSEnable as String] as? Int) == 1
        let socksHost = proxyDict[kCFNetworkProxiesSOCKSProxy as String] as? String ?? ""
        let socksPort = proxyDict[kCFNetworkProxiesSOCKSPort as String] as? Int ?? 0
        settings.append(ProxySetting(type: "SOCKS", host: socksHost, port: socksPort, enabled: socksEnabled))

        proxySettings = settings
    }

    private func checkVPN() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let addr = ptr {
            let name = String(cString: addr.pointee.ifa_name)
            if name.hasPrefix("utun") || name.hasPrefix("ipsec") || name.hasPrefix("ppp") {
                isVPNActive = true
                return
            }
            ptr = addr.pointee.ifa_next
        }
        isVPNActive = false
    }

    private func loadDNS() {
        var servers: [String] = []
        if let data = try? String(contentsOfFile: "/etc/resolv.conf", encoding: .utf8) {
            for line in data.components(separatedBy: "\n") {
                if line.hasPrefix("nameserver") {
                    let parts = line.components(separatedBy: " ")
                    if parts.count > 1 { servers.append(parts[1]) }
                }
            }
        }

        if servers.isEmpty {
            // Fallback: try to get from system config
            if let store = SCDynamicStoreCreate(nil, "DNSLookup" as CFString, nil, nil),
               let dns = SCDynamicStoreCopyValue(store, "State:/Network/Global/DNS" as CFString) as? [String: Any],
               let addrs = dns["ServerAddresses"] as? [String] {
                servers = addrs
            }
        }
        dnsServers = servers
    }

    private func checkNetworkType() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.usesInterfaceType(.wifi) { networkType = "WiFi" }
                else if path.usesInterfaceType(.cellular) { networkType = "Cellular" }
                else if path.usesInterfaceType(.wiredEthernet) { networkType = "Ethernet" }
                else if path.status == .satisfied { networkType = "Connected" }
                else { networkType = "Disconnected" }
                monitor.cancel()
            }
        }
        monitor.start(queue: .global(qos: .utility))
    }

    private func getActiveInterfaces() -> [(String, String)] {
        var result: [(String, String)] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return [] }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let addr = ptr {
            let name = String(cString: addr.pointee.ifa_name)
            if let sa = addr.pointee.ifa_addr, sa.pointee.sa_family == sa_family_t(AF_INET) {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(sa, socklen_t(sa.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
                let address = String(cString: host)
                if address != "127.0.0.1" {
                    result.append((name, address))
                }
            }
            ptr = addr.pointee.ifa_next
        }
        return result
    }
}
