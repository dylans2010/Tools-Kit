import SwiftUI
import CryptoKit

struct EncryptionToolDevTool: DevTool {
    let id = "encryption-tool"
    let name = "Encryption Tool"
    let category = DevToolCategory.security
    let icon = "lock.rectangle.stack"
    let description = "AES-GCM Encryption/Decryption"

    func render() -> some View {
        EncryptionToolView()
    }
}

struct EncryptionToolView: View {
    @StateObject private var viewModel = EncryptionToolViewModel()

    var body: some View {
        Form {
            Section("Plaintext") {
                TextEditor(text: $viewModel.plaintext)
                    .frame(height: 80)
            }

            Section("Encryption Key (32 bytes)") {
                TextField("Key (Hex)", text: $viewModel.keyHex)
                    .font(.monospaced(.caption)())
            }

            Section("Ciphertext (Base64)") {
                Text(viewModel.ciphertext)
                    .font(.monospaced(.caption)())
                    .textSelection(.enabled)

                Button("Encrypt") { viewModel.encrypt() }
            }
        }
    }
}

class EncryptionToolViewModel: ObservableObject {
    @Published var plaintext = ""
    @Published var keyHex = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"
    @Published var ciphertext = ""

    func encrypt() {
        guard let keyData = Data(hexString: keyHex),
              let plainData = plaintext.data(using: .utf8) else { return }

        let key = SymmetricKey(data: keyData)
        if let sealedBox = try? AES.GCM.seal(plainData, using: key) {
            ciphertext = sealedBox.combined?.base64EncodedString() ?? ""
        }
    }
}
