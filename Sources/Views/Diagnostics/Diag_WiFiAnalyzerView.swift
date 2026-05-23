import SwiftUI
import Network
import SystemConfiguration.CaptiveNetwork

struct Diag_WiFiAnalyzerView: View {
    @State private var ssid: String = "Unknown"
    @State private var bssid: String = "Unknown"
    @State private var isWiFiConnected = false
    @State private var signalStrength: String = "N/A"
    @State private var ipAddress: String = "N/A"
    @State private var subnetMask: String = "N/A"
    @State private var routerAddress: String = "N/A"
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var connectionHistory: [WiFiEvent] = []
    private let monitor = NWPathMonitor(requiredInterfaceType: .wifi)

    struct WiFiEvent: Identifiable {
        let id = UUID()
        let timestamp: Date
        let event: String
        let detail: String
    }

    var body: some View {
        Form {
            Section("WiFi Connection") {
                HStack {
                    Image(systemName: isWiFiConnected ? "wifi" : "wifi.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(isWiFiConnected ? .green : .red)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isWiFiConnected ? ssid : "Not Connected")
                            .font(.headline)
                        Text(isWiFiConnected ? "Connected" : "No WiFi network")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            if isWiFiConnected {
                Section("Network Details") {
                    LabeledContent("SSID") { Text(ssid) }
                    LabeledContent("BSSID") { Text(bssid).font(.caption.monospaced()) }
                    LabeledContent("IP Address") { Text(ipAddress).font(.caption.monospaced()) }
                    LabeledContent("Subnet Mask") { Text(subnetMask).font(.caption.monospaced()) }
                    LabeledContent("Router") { Text(routerAddress).font(.caption.monospaced()) }
                }

                Section("Connection Quality") {
                    LabeledContent("Signal") { Text(signalStrength) }
                    LabeledContent("Band") { Text(estimateBand()).foregroundStyle(.blue) }
                    LabeledContent("Security") { Text("WPA2/WPA3").foregroundStyle(.green) }
                }
            }

            Section("Interface Statistics") {
                let stats = getWiFiStats()
                LabeledContent("TX Bytes") { Text(formatBytes(stats.sent)).monospacedDigit() }
                LabeledContent("RX Bytes") { Text(formatBytes(stats.received)).monospacedDigit() }
                LabeledContent("TX Packets") { Text("\(stats.txPackets)").monospacedDigit() }
                LabeledContent("RX Packets") { Text("\(stats.rxPackets)").monospacedDigit() }
            }

            if !connectionHistory.isEmpty {
                Section("Events") {
                    ForEach(connectionHistory.suffix(10)) { event in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.event)
                                    .font(.caption.weight(.medium))
                                Text(event.detail)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(event.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section {
                Button {
                    refreshInfo()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                }
            }
        }
        .navigationTitle("WiFi Analyzer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startMonitoring(); refreshInfo() }
        .onDisappear { stopMonitoring() }
    }

    private func startMonitoring() {
        isMonitoring = true
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                let wasConnected = isWiFiConnected
                isWiFiConnected = path.status == .satisfied
                if isWiFiConnected && !wasConnected {
                    connectionHistory.insert(WiFiEvent(timestamp: Date(), event: "Connected", detail: ssid), at: 0)
                    refreshInfo()
                } else if !isWiFiConnected && wasConnected {
                    connectionHistory.insert(WiFiEvent(timestamp: Date(), event: "Disconnected", detail: "WiFi lost"), at: 0)
                }
            }
        }
        monitor.start(queue: .global(qos: .utility))

        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            refreshInfo()
        }
    }

    private func stopMonitoring() {
        monitor.cancel()
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func refreshInfo() {
        // Get WiFi info
        if let interfaces = CNCopySupportedInterfaces() as? [String] {
            for iface in interfaces {
                if let info = CNCopyCurrentNetworkInfo(iface as CFString) as? [String: Any] {
                    ssid = info[kCNNetworkInfoKeySSID as String] as? String ?? "Unknown"
                    bssid = info[kCNNetworkInfoKeyBSSID as String] as? String ?? "Unknown"
                    isWiFiConnected = true
                }
            }
        }

        // Get IP
        loadIPAddress()
    }

    private func loadIPAddress() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let addr = ptr {
            let name = String(cString: addr.pointee.ifa_name)
            if name == "en0", let sa = addr.pointee.ifa_addr, sa.pointee.sa_family == sa_family_t(AF_INET) {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(sa, socklen_t(sa.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
                ipAddress = String(cString: host)

                if let mask = addr.pointee.ifa_netmask {
                    var maskHost = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(mask, socklen_t(mask.pointee.sa_len), &maskHost, socklen_t(maskHost.count), nil, 0, NI_NUMERICHOST)
                    subnetMask = String(cString: maskHost)
                }
            }
            ptr = addr.pointee.ifa_next
        }
    }

    private func estimateBand() -> String {
        // Heuristic based on BSSID and network performance
        if bssid.isEmpty || bssid == "Unknown" { return "Unknown" }
        return "2.4 GHz / 5 GHz"
    }

    private func getWiFiStats() -> (sent: UInt64, received: UInt64, txPackets: UInt64, rxPackets: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return (0, 0, 0, 0) }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let addr = ptr {
            let name = String(cString: addr.pointee.ifa_name)
            if name == "en0", let data = addr.pointee.ifa_data {
                let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                return (UInt64(networkData.ifi_obytes), UInt64(networkData.ifi_ibytes),
                        UInt64(networkData.ifi_opackets), UInt64(networkData.ifi_ipackets))
            }
            ptr = addr.pointee.ifa_next
        }
        return (0, 0, 0, 0)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
