import SwiftUI
import Network

struct Diag_AirplaneModeView: View {
    @State private var networkStatus: String = "Checking..."
    @State private var isWiFi = false
    @State private var isCellular = false
    @State private var isExpensive = false
    @State private var possibleAirplaneMode = false
    @State private var monitor: NWPathMonitor?

    var body: some View {
        Form {
            Section("Network Status") {
                VStack(spacing: 12) {
                    Image(systemName: possibleAirplaneMode ? "airplane" : "antenna.radiowaves.left.and.right")
                        .font(.system(size: 50))
                        .foregroundStyle(possibleAirplaneMode ? .orange : .green)

                    Text(possibleAirplaneMode ? "Possible Airplane Mode" : "Network Available")
                        .font(.title3.bold())
                        .foregroundStyle(possibleAirplaneMode ? .orange : .green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Interface Status") {
                LabeledContent("Path Status") { Text(networkStatus) }
                LabeledContent("WiFi") {
                    Image(systemName: isWiFi ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isWiFi ? .green : .red)
                }
                LabeledContent("Cellular") {
                    Image(systemName: isCellular ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isCellular ? .green : .red)
                }
                LabeledContent("Expensive Connection") {
                    Text(isExpensive ? "Yes" : "No")
                }
            }

            Section {
                Text("Airplane mode detection is approximate. iOS does not expose a direct API for airplane mode status. This checks if all network interfaces are unavailable.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Airplane Mode")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startMonitoring() }
        .onDisappear { stopMonitoring() }
    }

    private func startMonitoring() {
        let mon = NWPathMonitor()
        mon.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                switch path.status {
                case .satisfied: networkStatus = "Connected"
                case .unsatisfied: networkStatus = "No Connection"
                case .requiresConnection: networkStatus = "Requires Connection"
                @unknown default: networkStatus = "Unknown"
                }

                isWiFi = path.usesInterfaceType(.wifi)
                isCellular = path.usesInterfaceType(.cellular)
                isExpensive = path.isExpensive
                possibleAirplaneMode = (path.status == .unsatisfied && !isWiFi && !isCellular)
            }
        }
        mon.start(queue: DispatchQueue.global(qos: .background))
        monitor = mon
    }

    private func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
    }
}
