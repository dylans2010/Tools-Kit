import SwiftUI
import Network

struct NetworkReachabilityView: View {
    @State private var pathStatus = "Checking..."
    @State private var interfaceType = "Unknown"
    @State private var isExpensive = false
    @State private var isConstrained = false
    @State private var monitor: NWPathMonitor?

    var body: some View {
        List {
            Section("Current Connection") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(pathStatus)
                        .foregroundStyle(statusColor)
                        .bold()
                }

                HStack {
                    Text("Interface")
                    Spacer()
                    Text(interfaceType)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Properties") {
                Toggle("Expensive (Cellular/Hotspot)", isOn: Binding(get: { isExpensive }, set: { _ in }))
                Toggle("Constrained (Low Data Mode)", isOn: Binding(get: { isConstrained }, set: { _ in }))
            }
        }
        .navigationTitle("Network Status")
        .onAppear(perform: startMonitoring)
        .onDisappear(perform: stopMonitoring)
    }

    private var statusColor: Color {
        switch pathStatus {
        case "Satisfied": return .green
        case "Unsatisfied": return .red
        default: return .orange
        }
    }

    private func startMonitoring() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.pathStatus = "\(path.status)".capitalized
                self.isExpensive = path.isExpensive
                self.isConstrained = path.isConstrained

                if path.usesInterfaceType(.wifi) {
                    self.interfaceType = "WiFi"
                } else if path.usesInterfaceType(.cellular) {
                    self.interfaceType = "Cellular"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.interfaceType = "Wired"
                } else {
                    self.interfaceType = "Other"
                }
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        self.monitor = monitor
    }

    private func stopMonitoring() {
        monitor?.cancel()
    }
}
