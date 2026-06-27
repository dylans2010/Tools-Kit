import SwiftUI

public struct PCCodeEntryView: View {
    @State private var code: String = ""
    @State private var pairingVM = PCPairingViewModel()
    @State private var settings = PCSettingsService.shared

    private var isValidating: Bool {
        if case .validating = pairingVM.state {
            return true
        }
        return false
    }

    public var body: some View {
        VStack(spacing: 30) {
            Text("Enter the 8-digit code shown on your Mac")
                .font(.headline)

            TextField("00000000", text: $code)
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .padding()

            Button("Pair") {
                Task {
                    // In real scenario, URL is configured in settings or discovered
                    let url = URL(string: settings.gatewayURL)
                    let host = url?.host ?? "MacBook-Pro.local"
                    let port = url?.port ?? 9876
                    await pairingVM.submitCode(code, host: host, port: port)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(code.count < 6 || isValidating)

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
        .navigationTitle("Enter Code")
    }
}
