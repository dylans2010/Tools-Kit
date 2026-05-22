import SwiftUI
import Network

struct Diag_WiFiStrengthView: View {
    @State private var status: String = "Unknown"
    @State private var interfaceType: String = "—"
    @State private var isExpensive: Bool = false
    @State private var isConstrained: Bool = false
    @State private var supportsIPv4: Bool = false
    @State private var supportsIPv6: Bool = false
    @State private var isMonitoring = false
    @State private var monitor: NWPathMonitor?

    var body: some View {
        Form {
            Section("WiFi Connection") {
                VStack(spacing: 12) {
                    Image(systemName: wifiIcon)
                        .font(.system(size: 50))
                        .foregroundStyle(status == "Satisfied" ? .green : .red)
                        .symbolEffect(.pulse, isActive: isMonitoring)

                    Text(status)
                        .font(.title2.bold())
                        .foregroundStyle(status == "Satisfied" ? .green : .red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Connection Details") {
                LabeledContent("Interface") { Text(interfaceType) }
                LabeledContent("Expensive (Cellular)") {
                    Image(systemName: isExpensive ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(isExpensive ? .orange : .green)
                }
                LabeledContent("Constrained (Low Data)") {
                    Image(systemName: isConstrained ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(isConstrained ? .orange : .green)
                }
                LabeledContent("IPv4") {
                    Text(supportsIPv4 ? "Supported" : "Not Available")
                }
                LabeledContent("IPv6") {
                    Text(supportsIPv6 ? "Supported" : "Not Available")
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "wifi.circle.fill")
                        Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    }
                }
            }
        }
        .navigationTitle("WiFi Strength")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startMonitoring() }
        .onDisappear { stopMonitoring() }
    }

    private var wifiIcon: String {
        switch status {
        case "Satisfied": return "wifi"
        case "Unsatisfied": return "wifi.slash"
        default: return "wifi.exclamationmark"
        }
    }

    private func startMonitoring() {
        let mon = NWPathMonitor()
        mon.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                switch path.status {
                case .satisfied: status = "Satisfied"
                case .unsatisfied: status = "Unsatisfied"
                case .requiresConnection: status = "Requires Connection"
                @unknown default: status = "Unknown"
                }

                isExpensive = path.isExpensive
                isConstrained = path.isConstrained
                supportsIPv4 = path.supportsIPv4
                supportsIPv6 = path.supportsIPv6

                if path.usesInterfaceType(.wifi) { interfaceType = "WiFi" }
                else if path.usesInterfaceType(.cellular) { interfaceType = "Cellular" }
                else if path.usesInterfaceType(.wiredEthernet) { interfaceType = "Ethernet" }
                else if path.usesInterfaceType(.loopback) { interfaceType = "Loopback" }
                else { interfaceType = "Other" }
            }
        }
        mon.start(queue: DispatchQueue.global(qos: .background))
        monitor = mon
        isMonitoring = true
    }

    private func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
        isMonitoring = false
    }
}
