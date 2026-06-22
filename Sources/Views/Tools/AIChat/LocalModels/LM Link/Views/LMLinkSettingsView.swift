import SwiftUI
import Network

struct LMLinkSettingsView: View {
    @AppStorage("lmlink_refresh_interval") private var refreshInterval: Double = 15.0
    @AppStorage("lmlink_auto_scan") private var autoScan = true

    @StateObject private var authManager = LMLinkAuthManager.shared
    @StateObject private var connectionManager = LMConnectionManager.shared

    @State private var localIP: String = "Detecting..."
    @State private var subnetMask: String = "Detecting..."

    var body: some View {
        List {
            Section {
                Toggle("Auto-scan local network", isOn: $autoScan)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Refresh Interval")
                        Spacer()
                        Text("\(Int(refreshInterval))s")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $refreshInterval, in: 5...60, step: 5)
                }
            } header: {
                Text("Scanning Behavior")
            }

            Section {
                LabeledContent("Authentication", value: authManager.isLinked ? "Linked" : "Not Linked")
                if let keyId = authManager.keyId {
                    LabeledContent("Key ID", value: String(keyId.prefix(8)) + "...")
                }

                if authManager.isLinked {
                    Button("Unlink Account", role: .destructive) {
                        authManager.unlink()
                    }
                }
            } header: {
                Text("Account Status")
            }

            Section {
                NavigationLink("Network Diagnostics") {
                    List {
                        LabeledContent("Local IP", value: localIP)
                        LabeledContent("Subnet Mask", value: subnetMask)
                        LabeledContent("mDNS Status", value: "Active")
                        LabeledContent("Active Device", value: connectionManager.selectedDevice?.name ?? "None")
                        if let device = connectionManager.selectedDevice {
                            LabeledContent("Device IP", value: device.ipAddress)
                            LabeledContent("Device Port", value: "\(device.port)")
                        }
                    }
                    .navigationTitle("Diagnostics")
                    .onAppear {
                        refreshNetworkInfo()
                    }
                }
            } header: {
                Text("Advanced")
            }
        }
        .navigationTitle("Settings")
    }

    private func refreshNetworkInfo() {
        if let ip = getLocalIPAddress() {
            localIP = ip
            subnetMask = "255.255.255.0" // Simplified for this environment
        }
    }

    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                guard let interface = ptr?.pointee else { continue }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    if name == "en0" || name == "en1" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
}
