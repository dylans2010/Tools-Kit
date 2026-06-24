import SwiftUI

struct OpenClawPairView: View {
    @StateObject private var viewModel = OpenClawPairingViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.step == 0 {
                    discoveryStep
                } else if viewModel.step == 1 {
                    manualStep
                } else if viewModel.step == 2 {
                    pairingLoadingStep
                } else {
                    successStep
                }
            }
            .navigationTitle("Pair Gateway")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var discoveryStep: some View {
        List {
            Section("Found Gateways") {
                if viewModel.discoveredDevices.isEmpty {
                    Text("Searching for OpenClaw gateways...")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.discoveredDevices) { device in
                        Button {
                            Task {
                                await viewModel.pair(with: BonjourPairingStrategy(service: device))
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(device.name).font(.headline)
                                    Text("\(device.host):\(device.port)").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                }
            }

            Section {
                Button("Enter Manually") { viewModel.step = 1 }
            }
        }
        .onAppear { viewModel.startDiscovery() }
    }

    private var manualStep: some View {
        Form {
            Section("Gateway Details") {
                TextField("Host (e.g. 192.168.1.5)", text: $viewModel.manualHost)
                TextField("Port", text: $viewModel.manualPort)
                    .keyboardType(.numberPad)
            }

            Section {
                Button("Pair Gateway") {
                    let host = viewModel.manualHost
                    let port = Int(viewModel.manualPort) ?? 18789
                    Task {
                        await viewModel.pair(with: ManualPairingStrategy(host: host, port: port))
                    }
                }
                .disabled(viewModel.manualHost.isEmpty)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var pairingLoadingStep: some View {
        VStack(spacing: 20) {
            ProgressView()
            Text("Establishing Trust...")
                .font(.headline)
        }
    }

    private var successStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Successfully Paired")
                .font(.title2.bold())
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
    }
}
