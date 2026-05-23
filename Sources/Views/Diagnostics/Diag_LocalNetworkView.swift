import SwiftUI

struct Diag_LocalNetworkView: View {
    @State private var devices: [LocalDevice] = [
        LocalDevice(name: "Router", ip: "192.168.1.1", type: "network"),
        LocalDevice(name: "This iPhone", ip: "192.168.1.15", type: "iphone"),
        LocalDevice(name: "MacBook Pro", ip: "192.168.1.22", type: "laptopcomputer")
    ]
    @State private var isScanning = false

    struct LocalDevice: Identifiable {
        let id = UUID()
        let name: String
        let ip: String
        let type: String
    }

    var body: some View {
        List {
            Section("Network Configuration") {
                LabeledContent("SSID", value: "Home_WiFi_5G")
                LabeledContent("Internal IP", value: "192.168.1.15")
                LabeledContent("Subnet Mask", value: "255.255.255.0")
            }

            Section("Detected Devices") {
                ForEach(devices) { device in
                    HStack {
                        Image(systemName: device.type)
                            .frame(width: 30)
                        VStack(alignment: .leading) {
                            Text(device.name)
                            Text(device.ip)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if isScanning {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("Scanning network...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button(action: startScan) {
                    Text(isScanning ? "Stop Scan" : "Scan Local Network")
                }
            }
        }
        .navigationTitle("Local Network")
    }

    private func startScan() {
        isScanning.toggle()
        if isScanning {
            // Simulate scan findings
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if isScanning {
                    devices.append(LocalDevice(name: "Apple TV", ip: "192.168.1.50", type: "appletv"))
                    isScanning = false
                }
            }
        }
    }
}
