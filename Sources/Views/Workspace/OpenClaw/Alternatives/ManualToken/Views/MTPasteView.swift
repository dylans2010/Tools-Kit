import SwiftUI
import Network

public struct MTPasteView: View {
    @State private var token: String = ""
    @State private var pairingVM = MTPairingViewModel()
    @State private var discoveryVM = TLANDiscoveryViewModel()

    public var body: some View {
        Form {
            Section("Gateway Selection") {
                if discoveryVM.results.isEmpty {
                    Text("Searching for gateways...")
                } else {
                    Picker("Gateway", selection: $pairingVM.selectedEndpoint) {
                        ForEach(discoveryVM.results, id: \.self) { result in
                            Text(result.endpoint.debugDescription).tag(Optional(result.endpoint))
                        }
                    }
                }
            }
            Section("Token Entry") {
                TextField("64-character token", text: $token)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)

                Button("Connect") {
                    if let endpoint = pairingVM.selectedEndpoint {
                        Task {
                            await pairingVM.pair(token: token, endpoint: endpoint)
                        }
                    }
                }
                .disabled(token.count < 64 || pairingVM.selectedEndpoint == nil)
            }

            if pairingVM.state != .idle {
                Section("Status") {
                    Text(statusMessage)
                }
            }
        }
        .navigationTitle("Manual Token")
        .task {
            await discoveryVM.startDiscovery()
        }
    }

    private var statusMessage: String {
        switch pairingVM.state {
        case .connecting: return "Connecting..."
        case .authenticating: return "Validating token..."
        case .paired: return "Successfully paired!"
        case .failed(let msg): return "Error: \(msg)"
        default: return ""
        }
    }
}
