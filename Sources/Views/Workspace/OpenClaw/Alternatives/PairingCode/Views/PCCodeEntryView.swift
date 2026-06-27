import SwiftUI
import Network

public struct PCCodeEntryView: View {
    @State private var code: String = ""
    @State private var pairingVM = PCPairingViewModel()
    @State private var discoveryVM = TLANDiscoveryViewModel()
    @State private var selectedEndpoint: NWEndpoint?

    public var body: some View {
        Form {
            Section("Gateway") {
                if discoveryVM.results.isEmpty {
                    Text("Searching for gateways...")
                } else {
                    Picker("Select Device", selection: $selectedEndpoint) {
                        ForEach(discoveryVM.results, id: \.self) { result in
                            Text(result.endpoint.debugDescription).tag(Optional(result.endpoint))
                        }
                    }
                }
            }
            Section("Enter Pairing Code") {
                TextField("000000", text: $code)
                    .font(.system(.title, design: .monospaced))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)

                Button("Pair") {
                    if case .hostPort(let host, let port) = selectedEndpoint {
                        Task {
                            await pairingVM.submitCode(code, host: host.debugDescription, port: Int(port.rawValue))
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(code.count < 6 || selectedEndpoint == nil)
            }
        }
        .padding()
        .navigationTitle("Enter Code")
        .task {
            await discoveryVM.startDiscovery()
        }
    }
}
