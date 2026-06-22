import SwiftUI
import Network

struct Diag_NetworkInfoView: View {
    @State private var interfaces: [NetworkInterface] = []
    @State private var connectionType: String = "Checking..."
    @State private var isExpensive = false
    @State private var isConstrained = false
    @State private var supportsIPv4 = false
    @State private var supportsIPv6 = false
    private let monitor = NWPathMonitor()

    struct NetworkInterface: Identifiable {
        let id = UUID()
        let name: String
        let address: String
        let family: String
    }

    var body: some View {
        Form {
            Section("Connection") {
                VStack(spacing: 12) {
                    Image(systemName: connectionIcon)
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text(connectionType)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Path Status") {
                LabeledContent("Connection Type") { Text(connectionType) }
                LabeledContent("Expensive") {
                    Text(isExpensive ? "Yes (cellular/hotspot)" : "No")
                        .foregroundStyle(isExpensive ? .orange : .green)
                }
                LabeledContent("Constrained") {
                    Text(isConstrained ? "Yes (Low Data Mode)" : "No")
                        .foregroundStyle(isConstrained ? .orange : .green)
                }
                LabeledContent("IPv4") {
                    Text(supportsIPv4 ? "Supported" : "Not Available")
                        .foregroundStyle(supportsIPv4 ? .green : .secondary)
                }
                LabeledContent("IPv6") {
                    Text(supportsIPv6 ? "Supported" : "Not Available")
                        .foregroundStyle(supportsIPv6 ? .green : .secondary)
                }
            }

            Section("Interfaces") {
                if interfaces.isEmpty {
                    Text("No interfaces detected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(interfaces, id: \.id) { iface in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(iface.name)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text(iface.family)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(Capsule())
                            }
                            Text(iface.address)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Network Info")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startMonitoring() }
        .onDisappear { monitor.cancel() }
    }

    private var connectionIcon: String {
        if connectionType.contains("WiFi") { return "wifi" }
        if connectionType.contains("Cellular") { return "antenna.radiowaves.left.and.right" }
        if connectionType.contains("Ethernet") { return "cable.connector" }
        return "network.slash"
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.usesInterfaceType(.wifi) {
                    connectionType = "WiFi"
                } else if path.usesInterfaceType(.cellular) {
                    connectionType = "Cellular"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    connectionType = "Ethernet"
                } else if path.status == .satisfied {
                    connectionType = "Connected"
                } else {
                    connectionType = "Disconnected"
                }
                isExpensive = path.isExpensive
                isConstrained = path.isConstrained
                supportsIPv4 = path.supportsIPv4
                supportsIPv6 = path.supportsIPv6
            }
        }
        monitor.start(queue: .global(qos: .utility))
        loadInterfaces()
    }

    private func loadInterfaces() {
        var list: [NetworkInterface] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return }
        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = ptr {
            let name = String(cString: addr.pointee.ifa_name)
            let family = addr.pointee.ifa_addr?.pointee.sa_family ?? 0
            if family == UInt8(AF_INET) || family == UInt8(AF_INET6) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(addr.pointee.ifa_addr, socklen_t(addr.pointee.ifa_addr.pointee.sa_len),
                           &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                let address = String(cString: hostname)
                let familyStr = family == UInt8(AF_INET) ? "IPv4" : "IPv6"
                list.append(NetworkInterface(name: name, address: address, family: familyStr))
            }
            ptr = addr.pointee.ifa_next
        }
        freeifaddrs(ifaddr)
        interfaces = list
    }
}
