import SwiftUI
import Network

struct NetworkReachabilityTool: DevTool {
    let id = UUID()
    let name = "Network Reachability"
    let category: DevToolCategory = .networking
    let icon = "wifi"
    let description = "Monitor network connection status"
    func render() -> some View { NetworkReachabilityDevToolView() }
}

struct NetworkReachabilityDevToolView: View {
    @StateObject private var monitor = NetworkReachabilityMonitor()

    var body: some View {
        Form {
            Section("Status") {
                LabeledContent("Connection") {
                    HStack {
                        Circle().fill(monitor.isConnected ? Color.green : Color.red).frame(width: 10, height: 10)
                        Text(monitor.isConnected ? "Connected" : "Disconnected")
                    }
                }
                LabeledContent("Interface", value: monitor.interfaceType)
                LabeledContent("Expensive", value: monitor.isExpensive ? "Yes" : "No")
                LabeledContent("Constrained", value: monitor.isConstrained ? "Yes" : "No")
            }
            Section("Connection History") {
                ForEach(Array(monitor.history.enumerated()), id: \.offset) { _, entry in
                    HStack {
                        Circle().fill(entry.connected ? Color.green : Color.red).frame(width: 8, height: 8)
                        Text(entry.description).font(.caption)
                        Spacer()
                        Text(entry.time).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Network Reachability")
    }
}

final class NetworkReachabilityMonitor: ObservableObject {
    struct HistoryEntry {
        let connected: Bool
        let description: String
        let time: String
    }
    @Published var isConnected = true
    @Published var interfaceType = "Unknown"
    @Published var isExpensive = false
    @Published var isConstrained = false
    @Published var history: [HistoryEntry] = []
    private let monitor = NWPathMonitor()
    private let formatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"; return f
    }()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isConnected = path.status == .satisfied
                self.isExpensive = path.isExpensive
                self.isConstrained = path.isConstrained
                if path.usesInterfaceType(.wifi) { self.interfaceType = "WiFi" }
                else if path.usesInterfaceType(.cellular) { self.interfaceType = "Cellular" }
                else if path.usesInterfaceType(.wiredEthernet) { self.interfaceType = "Ethernet" }
                else { self.interfaceType = "Other" }
                let entry = HistoryEntry(
                    connected: path.status == .satisfied,
                    description: path.status == .satisfied ? "Connected via \(self.interfaceType)" : "Disconnected",
                    time: self.formatter.string(from: Date())
                )
                self.history.insert(entry, at: 0)
                if self.history.count > 20 { self.history.removeLast() }
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }
    deinit { monitor.cancel() }
}
