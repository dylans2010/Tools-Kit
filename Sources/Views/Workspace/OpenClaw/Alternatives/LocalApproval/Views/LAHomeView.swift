import SwiftUI
import Network

public struct LAHomeView: View {
    @State private var pairingVM = LAPairingViewModel()
    @State private var discoveryVM = TLANDiscoveryViewModel()

    public var body: some View {
        List {
            Section("Nearby Devices") {
                if discoveryVM.results.isEmpty {
                    Text("Searching for devices...")
                } else {
                    ForEach(discoveryVM.results, id: \.self) { result in
                        Button(result.endpoint.debugDescription) {
                            Task {
                                await pairingVM.requestAccess(endpoint: result.endpoint)
                            }
                        }
                    }
                }
            }

            if pairingVM.state != .idle {
                Section("Status") {
                    Text(statusMessage)
                }
            }
        }
        .navigationTitle("Local Approval")
        .task {
            await discoveryVM.startDiscovery()
        }
        .onDisappear {
            Task {
                await discoveryVM.stopDiscovery()
            }
        }
    }

    private var statusMessage: String {
        switch pairingVM.state {
        case .connecting: return "Connecting..."
        case .awaitingApproval(let count): return "Waiting for approval (\(count)s)..."
        case .paired: return "Access Granted!"
        case .failed(let msg): return "Error: \(msg)"
        default: return ""
        }
    }
}
