import SwiftUI

struct LMLinkSettingsView: View {
    @AppStorage("lmlink_refresh_interval") private var refreshInterval: Double = 15.0
    @AppStorage("lmlink_auto_scan") private var autoScan = true

    var body: some View {
        List {
            Section(header: Text("Scanning Behavior")) {
                Toggle("Auto-scan local network", isOn: $autoScan)

                VStack(alignment: .leading) {
                    Text("Refresh Interval: \(Int(refreshInterval))s")
                    Slider(value: $refreshInterval, in: 5...60, step: 5)
                }
            }

            Section(header: Text("Advanced")) {
                NavigationLink("Network Diagnostics") {
                    List {
                        LabeledContent("Local IP", value: "192.168.1.50")
                        LabeledContent("Subnet Mask", value: "255.255.255.0")
                        LabeledContent("mDNS Status", value: "Active")
                    }
                    .navigationTitle("Diagnostics")
                }
            }
        }
        .navigationTitle("Settings")
    }
}
