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
                        Section("Interface") {
                            LabeledContent("Local IP", value: localIP)
                            LabeledContent("Subnet Mask", value: subnetMask)
                            LabeledContent("Discovery Mode", value: "Subnet Enumeration")
                        }

                        Section("Active Connection") {
                            LabeledContent("Active Device", value: connectionManager.selectedDevice?.name ?? "None")
                            if let device = connectionManager.selectedDevice {
                                LabeledContent("Device IP", value: device.ipAddress)
                                LabeledContent("Device Port", value: "\(device.port)")
                                LabeledContent("Status", value: device.status.rawValue.capitalized)
                            }
                        }

                        Section("Discovery") {
                            LabeledContent("Is Scanning", value: LMDeviceDiscoveryService.shared.isScanning ? "Yes" : "No")
                            LabeledContent("Found Devices", value: "\(LMDeviceDiscoveryService.shared.discoveredDevices.count)")
                        }

                        TruthMirrorView()
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

struct TruthMirrorView: View {
    @State private var rawJSON: String = ""
    @State private var isFetching = false
    @State private var latency: Double?

    var body: some View {
        Section("Truth Mirror (Phase 9)") {
            if let device = LMConnectionManager.shared.selectedDevice {
                Button {
                    fetchRaw(device: device)
                } label: {
                    HStack {
                        if isFetching { ProgressView().padding(.trailing, 8) }
                        Text("Fetch Raw /v1/models")
                    }
                }
                .disabled(isFetching)

                if let latency = latency {
                    LabeledContent("Latency", value: String(format: "%.3f s", latency))
                }

                if !rawJSON.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Raw JSON Response")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        ScrollView {
                            Text(rawJSON)
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                        }
                        .frame(height: 200)
                    }
                    .padding(.vertical, 8)
                }
            } else {
                Text("No device selected for Truth Mirror")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }

    private func fetchRaw(device: LMDevice) {
        isFetching = true
        rawJSON = ""
        latency = nil
        let start = Date()

        Task {
            do {
                let url = URL(string: "\(device.baseURL)/v1/models")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let end = Date()

                await MainActor.run {
                    self.latency = end.timeIntervalSince(start)
                    if let json = try? JSONSerialization.jsonObject(with: data),
                       let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                       let prettyString = String(data: prettyData, encoding: .utf8) {
                        self.rawJSON = prettyString
                    } else {
                        self.rawJSON = String(data: data, encoding: .utf8) ?? "Unable to decode"
                    }
                    self.isFetching = false
                }
            } catch {
                await MainActor.run {
                    self.rawJSON = "Error: \(error.localizedDescription)"
                    self.isFetching = false
                }
            }
        }
    }
}
