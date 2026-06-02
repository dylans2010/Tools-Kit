import SwiftUI
import CryptoKit

struct RSAGeneratorDevTool: DevTool {
    let id = "rsa-generator"
    let name = "RSA Key Pair Generator"
    let category: DevToolCategory = .security
    let icon = "key.icloud"
    let description = "Generate RSA Public and Private key pairs (2048-bit)"

    func render() -> some View {
        RSAGeneratorView()
    }
}

struct RSAGeneratorView: View {
    @State private var publicKey = ""
    @State private var privateKey = ""
    @State private var isGenerating = false

    var body: some View {
        Form {
            Section {
                Button {
                    generateKeys()
                } label: {
                    if isGenerating {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Generate 2048-bit RSA Pair")
                    }
                }
                .disabled(isGenerating)
                .frame(maxWidth: .infinity)
            }

            if !publicKey.isEmpty {
                Section("Public Key") {
                    Text(publicKey)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                }
                Section("Private Key") {
                    Text(privateKey)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
    }

    private func generateKeys() {
        isGenerating = true
        // Note: RSA generation is heavy, usually done in background.
        // For simulation of a real tool using SecKey:
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048
        ]

        DispatchQueue.global(qos: .userInitiated).async {
            var error: Unmanaged<CFError>?
            guard let privKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
                DispatchQueue.main.async {
                    self.publicKey = "Error: \(error!.takeRetainedValue().localizedDescription)"
                    self.isGenerating = false
                }
                return
            }

            let pubKey = SecKeyCopyPublicKey(privKey)!

            let privData = SecKeyCopyExternalRepresentation(privKey, &error) as Data?
            let pubData = SecKeyCopyExternalRepresentation(pubKey, &error) as Data?

            DispatchQueue.main.async {
                self.publicKey = pubData?.base64EncodedString() ?? "Error exporting public key"
                self.privateKey = privData?.base64EncodedString() ?? "Error exporting private key"
                self.isGenerating = false
            }
        }
    }
}
