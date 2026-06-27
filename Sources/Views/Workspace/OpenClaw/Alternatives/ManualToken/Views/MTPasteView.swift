import SwiftUI

public struct MTPasteView: View {
    @State private var token: String = ""
    @State private var pairingVM = MTPairingViewModel()
    @State private var settings = MTSettingsService.shared

    public var body: some View {
        VStack(spacing: 20) {
            Text("Paste the token from your Mac")
                .font(.headline)

            TextField("Token (64 chars)", text: $token)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .padding()

            Button("Validate & Pair") {
                Task {
                    await pairingVM.pair(token: token, host: settings.gatewayHost, port: settings.gatewayPort)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(token.count < 10 || pairingVM.state == .validating)

            if pairingVM.state == .validating {
                ProgressView("Validating...")
            }

            if case .failed(let error) = pairingVM.state {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .padding()
        .navigationTitle("Manual Token")
    }
}
