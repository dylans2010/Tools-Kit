import SwiftUI

struct TrustedLANView: View {
    @State private var viewModel = TrustedLANViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Trusted Local Network", systemImage: "shield.checkered")
                        .font(.headline)
                    Text("Select your Mac below. An approval dialog will appear on your Mac's screen. Once approved, this iPhone will be permanently trusted.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Discovered Macs") {
                if viewModel.discoveredServices.isEmpty {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("Searching for OpenClaw Gateways...")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(viewModel.discoveredServices) { service in
                        Button {
                            Task {
                                await viewModel.pair(with: service)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(service.name)
                                        .font(.body.bold())
                                    Text(service.host)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if viewModel.isPairing {
                                    ProgressView()
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            if let error = viewModel.error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("STATUS: \(viewModel.pairingStatus)")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)

                    if viewModel.pairingStatus == "Paired!" {
                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .navigationTitle("Trusted LAN")
        .onAppear {
            viewModel.startDiscovery()
        }
    }
}
