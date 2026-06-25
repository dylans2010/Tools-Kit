import SwiftUI

struct OpenClawPairView: View {
    @StateObject private var viewModel = OpenClawPairingViewModel()
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var diagnostics = OpenClawDiagnosticsManager.shared

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
        VStack(alignment: .leading, spacing: 4) {
            Text(message)
                .font(.caption.bold())

            if let lastLog = diagnostics.logs.last(where: { $0.contains("[ERROR]") }) {
                Text(lastLog)
                    .font(.system(size: 8, design: .monospaced))
                    .opacity(0.8)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
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

            VStack(spacing: 8) {
                protocolProgressRow(label: "Socket Connected", active: isStateAtLeast(.socketConnected))
                protocolProgressRow(label: "Connect Sent", active: isStateAtLeast(.waitingChallenge))
                protocolProgressRow(label: "Challenge Received", active: isStateAtLeast(.authenticating))
                protocolProgressRow(label: "Authentication Sent", active: isStateAtLeast(.connected))
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)

            // Real-time protocol log peek
            if let lastProtocolLog = diagnostics.logs.last(where: { $0.contains("[PROTOCOL]") }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Protocol Traffic")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(lastProtocolLog)
                        .font(.system(size: 8, design: .monospaced))
                        .lineLimit(2)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(Color.black.opacity(0.05))
                .cornerRadius(4)
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func protocolProgressRow(label: String, active: Bool) -> some View {
        HStack {
            Image(systemName: active ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(active ? .green : .secondary)
            Text(label)
                .foregroundStyle(active ? .primary : .secondary)
            Spacer()
        }
    }

    private func isStateAtLeast(_ state: ConnectionState) -> Bool {
        let currentState = OpenClawService.shared.connectionState
        switch (state, currentState) {
        case (.socketConnected, .socketConnected), (.socketConnected, .waitingChallenge), (.socketConnected, .authenticating), (.socketConnected, .connected):
            return true
        case (.waitingChallenge, .waitingChallenge), (.waitingChallenge, .authenticating), (.waitingChallenge, .connected):
            return true
        case (.authenticating, .authenticating), (.authenticating, .connected):
            return true
        case (.connected, .connected):
            return true
        default:
            return false
        }
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
