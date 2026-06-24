import SwiftUI

struct OpenClawPairView: View {
    @State private var viewModel = OpenClawPairingViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                switch viewModel.currentStep {
                case .requirements:
                    requirementsStep
                case .discovery:
                    discoveryStep
                case .manualInput:
                    manualInputStep
                case .connecting:
                    connectingStep
                case .success:
                    successStep
                }
            }
            .navigationTitle("Pair OpenClaw")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var requirementsStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "desktopcomputer.and.iphone")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("OpenClaw Pairing")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 10) {
                Label("OpenClaw Gateway running on Mac", systemImage: "checkmark.circle.fill")
                Label("Both devices on same WiFi", systemImage: "checkmark.circle.fill")
                Label("Port 18789 accessible", systemImage: "checkmark.circle.fill")
            }
            .font(.subheadline)

            Spacer()

            Button("Find Gateway") {
                viewModel.currentStep = .discovery
                viewModel.startDiscovery()
            }
            .buttonStyle(.borderedProminent)

            Button("Manual Entry") {
                viewModel.currentStep = .manualInput
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
        }
        .padding()
    }

    private var discoveryStep: some View {
        VStack {
            List(viewModel.discoveredDevices) { device in
                Button {
                    viewModel.selectedDevice = device
                    viewModel.currentStep = .connecting
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
            .overlay {
                if viewModel.discoveredDevices.isEmpty {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text("Searching for OpenClaw Gateways...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button("Enter IP Manually") {
                viewModel.stopDiscovery()
                viewModel.currentStep = .manualInput
            }
            .padding()
        }
    }

    private var manualInputStep: some View {
        Form {
            Section("Gateway Details") {
                TextField("Host (IP or .local)", text: $viewModel.manualHost)
                TextField("Port", text: $viewModel.manualPort)
                    .keyboardType(.numberPad)
            }

            Section("Authentication") {
                SecureField("Pairing Token", text: $viewModel.token)
            }

            Button("Connect") {
                Task { await viewModel.pairManual() }
            }
            .disabled(viewModel.manualHost.isEmpty || viewModel.token.isEmpty)
        }
    }

    private var connectingStep: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            if let device = viewModel.selectedDevice {
                Text("Connecting to \(device.name)...")
                    .font(.headline)
            }

            SecureField("Enter Token", text: $viewModel.token)
                .textFieldStyle(.roundedBorder)
                .padding()

            Button("Authenticate") {
                if let device = viewModel.selectedDevice {
                    Task { await viewModel.pair(device: device) }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.token.isEmpty)

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .padding()
    }

    private var successStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("Successfully Paired!")
                .font(.title2.bold())

            Text("Your iPhone is now authorized to control OpenClaw on this Mac.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
