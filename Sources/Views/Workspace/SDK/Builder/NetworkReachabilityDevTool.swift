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
        Form {
            Section("Status") {
                HStack {
                    Text(viewModel.status.description)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(.white)
                        .background(viewModel.status == .satisfied ? Color.green : Color.red, in: RoundedRectangle(cornerRadius: 4))
                    Spacer()
                    if viewModel.isExpensive {
                        Text("Expensive Connection")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundStyle(.white)
                            .background(Color.orange, in: RoundedRectangle(cornerRadius: 4))
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

            Section {
                HStack {
                    Text("History")
                        .font(.headline)
                    Spacer()
                    Button("Clear") {
                        viewModel.history.removeAll()
                    }
                    .font(.caption)
                    .disabled(viewModel.history.isEmpty)
                }

                if viewModel.history.isEmpty {
                    ContentUnavailableView("No History", systemImage: "clock", description: Text("Your activity will appear here."))
                        .frame(height: 200)
                } else {
                    List {
                        ForEach(viewModel.history) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.subheadline.bold())
                                Text(item.detail)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .foregroundStyle(.secondary)
                                Text(item.timestamp, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .frame(height: 300)
                }
            } header: {
                Text("Log")
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

#Preview {
    NetworkReachabilityView()
}
