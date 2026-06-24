import SwiftUI

struct OpenClawPairView: View {
    @StateObject private var viewModel = OpenClawPairingViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                if let error = viewModel.errorMessage {
                    errorBanner(error)
                }

                switch viewModel.step {
                case 0:
                    discoveryStep
                case 1:
                    manualStep
                case 2:
                    pairingLoadingStep
                case 3:
                    successStep
                default:
                    discoveryStep
                }
            }
            .navigationTitle("Pair Gateway")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if viewModel.step == 1 {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") { viewModel.step = 0 }
                    }
                }
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1))
            .foregroundStyle(.red)
    }

    private var discoveryStep: some View {
        List {
            Section("Found Gateways") {
                if viewModel.discoveredDevices.isEmpty {
                    HStack {
                        ProgressView().padding(.trailing, 8)
                        Text("Searching for OpenClaw gateways...")
                            .foregroundStyle(.secondary)
                    }
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
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    viewModel.step = 1
                } label: {
                    Label("Enter Manually", systemImage: "keyboard")
                }
            }
        }
        .onAppear { viewModel.startDiscovery() }
    }

    private var manualStep: some View {
        Form {
            Section("Gateway Details") {
                TextField("Host (e.g. 192.168.1.5)", text: $viewModel.manualHost)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                TextField("Port", text: $viewModel.manualPort)
                    .keyboardType(.numberPad)
            }

            Section {
                Button {
                    let host = viewModel.manualHost
                    let port = Int(viewModel.manualPort) ?? 18789
                    Task {
                        await viewModel.pair(with: ManualPairingStrategy(host: host, port: port))
                    }
                } label: {
                    if viewModel.isPairing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Pair Gateway")
                    }
                }
                .disabled(viewModel.manualHost.isEmpty || viewModel.isPairing)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var pairingLoadingStep: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Establishing Trust...")
                .font(.headline)
            Text("Performing secure handshake with gateway")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var successStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Successfully Paired")
                .font(.title2.bold())
            Text("Your gateway is now ready to use.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
