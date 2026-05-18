import SwiftUI
import Network

struct NetworkReachabilityDevTool: DevTool {
    let id = "network-reachability"
    let name = "Network Reachability"
    let category = DevToolCategory.networking
    let icon = "wifi"
    let description = "Check network connectivity status"

    func render() -> some View {
        NetworkReachabilityView()
    }
}

struct NetworkReachabilityView: View {
    @StateObject private var viewModel = NetworkReachabilityViewModel()

    var body: some View {
        Form {
            Section("Current Status") {
                HStack {
                    Image(systemName: viewModel.isConnected ? "wifi" : "wifi.slash")
                        .foregroundStyle(viewModel.isConnected ? .green : .red)
                    Text(viewModel.isConnected ? "Connected" : "Disconnected")
                }
                LabeledContent("Interface", value: viewModel.interfaceType)
            }

            Section("Diagnostics") {
                LabeledContent("Expensive", value: viewModel.isExpensive ? "Yes" : "No")
                LabeledContent("Constrained", value: viewModel.isConstrained ? "Yes" : "No")
            }
        }
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
}

class NetworkReachabilityViewModel: ObservableObject {
    private let monitor = NWPathMonitor()
    @Published var isConnected = false
    @Published var interfaceType = "Unknown"
    @Published var isExpensive = false
    @Published var isConstrained = false

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
                self?.isConstrained = path.isConstrained

                if path.usesInterfaceType(.wifi) {
                    self?.interfaceType = "WiFi"
                } else if path.usesInterfaceType(.cellular) {
                    self?.interfaceType = "Cellular"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.interfaceType = "Ethernet"
                } else {
                    self?.interfaceType = "Other"
                }
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }

    func stopMonitoring() {
        monitor.cancel()
    }
}
