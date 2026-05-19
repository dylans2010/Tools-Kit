import SwiftUI
import CryptoKit

struct EncryptionToolDevTool: DevTool {
    let id = "encryption-tool"
    let name = "Encryption Tool"
    let category = DevToolCategory.security
    let icon = "key.fill"
    let description = "Encrypt and decrypt data using AES-GCM"

    func render() -> some View {
        EncryptionToolView()
    }
}

struct EncryptionToolView: View {
    @StateObject private var viewModel = EncryptionToolViewModel()

    var body: some View {
        Form {
            Section("Keys") {
                HStack {
                    SecureField("Password / Key", text: $viewModel.key)
                    Button("Gen") { viewModel.generateKey() }
                }
            }

            Section("Input") {
                TextEditor(text: $viewModel.input)
                    .frame(height: 100)
            }

            Section("Actions") {
                HStack {
                    Button("Encrypt") { viewModel.encrypt() }
                        .buttonStyle(.borderedProminent)
                    Button("Decrypt") { viewModel.decrypt() }
                        .buttonStyle(.bordered)
                }
            }

            Section("Output") {
                Text(viewModel.output)
                    .font(.system(.caption2, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(minHeight: 60)

                if !viewModel.error.isEmpty {
                    Text(viewModel.error).font(.caption).foregroundStyle(.red)
                }
            }
        }
    }
}

class EncryptionToolViewModel: ObservableObject {
    @Published var key = "secret-key-32-chars-long-!!!!!!"
    @Published var input = "Sensitive data"
    @Published var output = ""
    @Published var error = ""

    func generateKey() {
        let key = SymmetricKey(size: .bits256)
        self.key = key.withUnsafeBytes { Data($0).base64EncodedString() }
    }

    func encrypt() {
        error = ""
        guard let data = input.data(using: .utf8),
              let keyData = Data(base64Encoded: key) ?? key.data(using: .utf8) else {
            error = "Invalid Key"
            return
        }

        do {
            let symmetricKey = SymmetricKey(data: keyData.prefix(32))
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
            output = sealedBox.combined?.base64EncodedString() ?? ""
        } catch {
            self.error = error.localizedDescription
        }
    }

    func decrypt() {
        error = ""
        guard let combinedData = Data(base64Encoded: input),
              let keyData = Data(base64Encoded: key) ?? key.data(using: .utf8) else {
            error = "Invalid Data or Key"
            return
        }

        do {
            let symmetricKey = SymmetricKey(data: keyData.prefix(32))
            let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            output = String(data: decryptedData, encoding: .utf8) ?? "Decrypted data is not UTF8"
        } catch {
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    EncryptionToolView()
}
