import SwiftUI
import CryptoKit

struct HMACCalculatorDevTool: DevTool {
    let id = "hmac-calculator"
    let name = "HMAC Calculator"
    let category: DevToolCategory = .security
    let icon = "number.circle.fill"
    let description = "Calculate HMAC-SHA256 signatures for messages"

    func render() -> some View {
        HMACCalculatorView()
    }
}

struct HMACCalculatorView: View {
    @State private var key = ""
    @State private var message = ""
    @State private var hmac = ""

    var body: some View {
        Form {
            Section("Key") {
                TextField("Secret Key", text: $key)
                    .font(.system(.body, design: .monospaced))
            }
            Section("Message") {
                TextEditor(text: $message)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 100)
            }
            Button("Calculate HMAC-SHA256") {
                calculate()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)

            if !hmac.isEmpty {
                Section("Result (Hex)") {
                    Text(hmac)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
    }

    private func calculate() {
        guard let keyData = key.data(using: .utf8), let msgData = message.data(using: .utf8) else { return }
        let symKey = SymmetricKey(data: keyData)
        let signature = HMAC<SHA256>.authenticationCode(for: msgData, using: symKey)
        hmac = signature.map { String(format: "%02x", $0) }.joined()
    }
}
