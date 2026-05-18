import SwiftUI
import Network

struct NetworkReachabilityDevTool: DevTool {
    let id = "network-reachability"
    let name = "Network Reachability"
    let category = DevToolCategory.networking
    let icon = "wifi"
    let description = "Monitor network interfaces and reachability"

    func render() -> some View {
        NetworkReachabilityView()
    }
}

struct NetworkReachabilityView: View {
    @StateObject private var viewModel = NetworkReachabilityViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Network Reachability",
                description: "Real-time monitoring of network interfaces, connectivity status, and data usage paths.",
                icon: "wifi"
            )
            .padding()

            Form {
                Section("Status") {
                    HStack {
                        StatusBadge(
                            text: viewModel.status.description,
                            color: viewModel.status == .satisfied ? .green : .red
                        )
                        Spacer()
                        if viewModel.isExpensive {
                            StatusBadge(text: "Expensive Connection", color: .orange)
                        }
                    }

                    LabeledContent("Interface Type", value: viewModel.interfaceType)
                }

                Section("Capabilities") {
                    Toggle("DNS Required", isOn: .constant(true)).disabled(true)
                    Toggle("IPv4 Supported", isOn: .constant(viewModel.supportsIPv4)).disabled(true)
                    Toggle("IPv6 Supported", isOn: .constant(viewModel.supportsIPv6)).disabled(true)
                    Toggle("VPN Active", isOn: .constant(viewModel.isVPNActive)).disabled(true)
                }

                Section("Active Interfaces") {
                    ForEach(viewModel.interfaces, id: \.self) { interface in
                        Label(interface, systemImage: interfaceIcon(for: interface))
                    }
                }

                Section("Log") {
                    HistoryView(history: viewModel.history) { _ in } onClear: {
                        viewModel.history.removeAll()
                    }
                    .frame(height: 200)
                }
            }
        }
    }

    private func interfaceIcon(for type: String) -> String {
        switch type.lowercased() {
        case "wifi": return "wifi"
        case "cellular": return "antenna.radiowaves.left.and.right"
        case "wiredethernet": return "cable.connector"
        default: return "network"
        }
    }
}

class NetworkReachabilityViewModel: ObservableObject {
    @Published var status: NWPath.Status = .unsatisfied
    @Published var interfaceType = "None"
    @Published var isExpensive = false
    @Published var supportsIPv4 = false
    @Published var supportsIPv6 = false
    @Published var isVPNActive = false
    @Published var interfaces: [String] = []
    @Published var history: [HistoryItem] = []

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.update(path)
            }
        }
        monitor.start(queue: queue)
    }

    private func update(_ path: NWPath) {
        let oldStatus = status
        status = path.status
        isExpensive = path.isExpensive
        supportsIPv4 = path.supportsIPv4
        supportsIPv6 = path.supportsIPv6

        var currentInterfaces: [String] = []
        if path.usesInterfaceType(.wifi) { currentInterfaces.append("WiFi") }
        if path.usesInterfaceType(.cellular) { currentInterfaces.append("Cellular") }
        if path.usesInterfaceType(.wiredEthernet) { currentInterfaces.append("Ethernet") }
        if path.usesInterfaceType(.other) { currentInterfaces.append("Other") }
        interfaces = currentInterfaces
        interfaceType = currentInterfaces.joined(separator: ", ")

        if oldStatus != status {
            history.insert(HistoryItem(title: "Status Changed", detail: "Network status changed to \(status.description)"), at: 0)
        }
    }
}

extension NWPath.Status: CustomStringConvertible {
    public var description: String {
        switch self {
        case .satisfied: return "Satisfied"
        case .unsatisfied: return "Unsatisfied"
        case .requiresConnection: return "Requires Connection"
        @unknown default: return "Unknown"
        }
    }
}
