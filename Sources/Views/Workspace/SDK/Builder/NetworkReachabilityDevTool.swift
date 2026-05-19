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
        List {
            Section("Status") {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(viewModel.status == .satisfied ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                            .shadow(color: (viewModel.status == .satisfied ? Color.green : Color.red).opacity(0.3), radius: 4)

                        Text(viewModel.status.description)
                            .font(.title3.bold())

                        Spacer()

                        if viewModel.isExpensive {
                            Text("EXPENSIVE")
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundStyle(.orange)
                                .cornerRadius(4)
                        }
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Primary Interface").font(.caption2).foregroundStyle(.secondary)
                            Text(viewModel.interfaceType).font(.subheadline.bold())
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Cellular Data").font(.caption2).foregroundStyle(.secondary)
                            Text(viewModel.interfaces.contains("Cellular") ? "On" : "Off").font(.subheadline.bold())
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Capabilities") {
                CapabilityRow(label: "IPv4 Support", active: viewModel.supportsIPv4)
                CapabilityRow(label: "IPv6 Support", active: viewModel.supportsIPv6)
                CapabilityRow(label: "VPN Active", active: viewModel.isVPNActive)
                CapabilityRow(label: "Low Data Mode", active: viewModel.isLowDataMode)
            }

            Section("Active Interfaces") {
                if viewModel.interfaces.isEmpty {
                    Text("No active interfaces").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.interfaces, id: \.self) { interface in
                        HStack {
                            Image(systemName: interfaceIcon(for: interface))
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            Text(interface)
                            Spacer()
                            Text("Connected").font(.caption2).foregroundStyle(.green)
                        }
                    }
                }
            }

            Section {
                if viewModel.history.isEmpty {
                    ContentUnavailableView("Monitoring...", systemImage: "antenna.radiowaves.left.and.right", description: Text("Network changes will be logged here."))
                } else {
                    ForEach(viewModel.history) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.title)
                                    .font(.subheadline.bold())
                                Spacer()
                                Text(item.timestamp, style: .time)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.tertiary)
                            }
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            } header: {
                HStack {
                    Text("Activity Log")
                    Spacer()
                    if !viewModel.history.isEmpty {
                        Button("Clear") { viewModel.history.removeAll() }.font(.caption)
                    }
                }
            }
        }
        .navigationTitle("Reachability")
    }
}

struct CapabilityRow: View {
    let label: String
    let active: Bool

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Image(systemName: active ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(active ? .green : .secondary)
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
    @Published var isLowDataMode = false
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
        isLowDataMode = path.isConstrained

        var currentInterfaces: [String] = []
        if path.usesInterfaceType(.wifi) { currentInterfaces.append("WiFi") }
        if path.usesInterfaceType(.cellular) { currentInterfaces.append("Cellular") }
        if path.usesInterfaceType(.wiredEthernet) { currentInterfaces.append("Ethernet") }
        if path.usesInterfaceType(.other) { currentInterfaces.append("Other") }
        interfaces = currentInterfaces
        interfaceType = currentInterfaces.first ?? "None"

        if oldStatus != status {
            history.insert(HistoryItem(title: "Connection: \(status.description)", detail: "Active: \(interfaceType) | Expensive: \(isExpensive)"), at: 0)
            if history.count > 50 { history.removeLast() }
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
