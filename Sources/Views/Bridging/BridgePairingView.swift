import SwiftUI

struct BridgePairingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pairingMethod: PairingMethod = .qr
    @State private var hostURL: String = ""
    @State private var port: String = "8080"
    @State private var pairingCode: String = ""
    @State private var platform: BridgePlatform = .macos
    @State private var deviceName: String = ""
    @State private var isValidating = false
    @State private var error: String?

    enum PairingMethod: String, CaseIterable, Identifiable {
        case qr = "QR Scan"
        case code = "Pairing Code"
        case manual = "Manual Entry"
        var id: String { rawValue }
    }

    private var isFormValid: Bool {
        if deviceName.isEmpty { return false }

        switch pairingMethod {
        case .qr:
            return false // QR scanner not implemented in this UI
        case .code:
            return pairingCode.count == 6
        case .manual:
            return !hostURL.isEmpty && !port.isEmpty
        }
    }

    var body: some View {
        Form {
            Section {
                Picker("Method", selection: $pairingMethod) {
                    ForEach(PairingMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                BridgePlatformSelectorView(selectedPlatform: $platform)
                    .padding(.vertical, 8)
            }

            Section {
                switch pairingMethod {
                case .qr:
                    qrScannerPlaceholder
                case .code:
                    TextField("6-Digit Pairing Code", text: $pairingCode)
                        .keyboardType(.numberPad)
                case .manual:
                    TextField("Host URL (e.g. http://192.168.1.5)", text: $hostURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }
            } header: {
                Text("Host Details")
            }

            Section {
                TextField("Device Name (e.g. Work MacBook)", text: $deviceName)
            } header: {
                Text("Device Info")
            }

            if let error = error {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            Section {
                Button {
                    validateAndPair()
                } label: {
                    HStack {
                        if isValidating { ProgressView().padding(.trailing, 8) }
                        Text("Confirm and Pair")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(isValidating || !isFormValid)
            }
        }
        .onReceive(TKBridgeClient.shared.$state) { state in
            switch state {
            case .connected:
                isValidating = false
                dismiss()
            case .failed(let msg):
                isValidating = false
                self.error = msg
            case .hostFound(let ip, let code):
                self.hostURL = ip
                self.pairingCode = code
                self.pairingMethod = .code
            default:
                break
            }
        }
        .navigationTitle("Pair New Device")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private var qrScannerPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text("Align host QR code within the frame")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func validateAndPair() {
        isValidating = true
        error = nil

        if pairingMethod == .code {
            TKBridgeClient.shared.pair(host: hostURL, code: pairingCode)
            return
        }

        Task {
            let finalURL: String
            let finalPort: Int

            switch pairingMethod {
            case .manual:
                finalURL = hostURL
                finalPort = Int(port) ?? 8080
            case .code:
                return // Handled above
            case .qr:
                await MainActor.run {
                    self.error = "QR Scanner is not available in this build."
                    self.isValidating = false
                }
                return
            }

            guard let url = URL(string: finalURL) else {
                await MainActor.run {
                    self.error = "Invalid Host URL"
                    self.isValidating = false
                }
                return
            }

            let success = await BridgeService.shared.testConnection(host: url, port: finalPort)

            await MainActor.run {
                if success {
                    let device = BridgeDevice(
                        name: deviceName,
                        platform: platform,
                        hostURL: url,
                        port: finalPort
                    )
                    // In a real flow, the token comes from the host during pairing
                    BridgeSessionManager.shared.addDevice(device, token: "session_\(UUID().uuidString)")
                    dismiss()
                } else {
                    self.error = "Failed to connect to host. Ensure the bridge server is running."
                }
                self.isValidating = false
            }
        }
    }
}
