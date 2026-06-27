import SwiftUI

public struct LAHomeView: View {
    @State private var pairingVM = LAPairingViewModel()
    @State private var settings = LASettingsService.shared

    public var body: some View {
        List {
            Section("Method") {
                Text("Local Approval")
                Text("Your iPhone connects to your Mac and asks for approval. Your Mac shows a dialog with your iPhone's details. You click Allow.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Discovered Macs") {
                if pairingVM.discoveredResults.isEmpty {
                    HStack {
                        ProgressView()
                        Text("Searching...")
                            .padding(.leading, 8)
                    }
                } else {
                    ForEach(pairingVM.discoveredResults, id: \.self) { result in
                        Button(result.endpoint.debugDescription) {
                            Task {
                                await pairingVM.startPairing(with: result)
                            }
                        }
                        .disabled(pairingVM.state == .connecting || pairingVM.state == .awaitingApproval(0))
                    }
                }
            }

            if case .awaitingApproval(let timeout) = pairingVM.state {
                Section {
                    HStack {
                        ProgressView()
                        Text("Waiting for Mac approval...")
                            .padding(.leading, 8)
                    }
                }
            }

            if case .exchangeFailed(let error) = pairingVM.state {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Local Approval")
        .task {
            await pairingVM.startDiscovery()
        }
        .onDisappear {
            Task {
                await pairingVM.stopDiscovery()
            }
        }
    }
}
