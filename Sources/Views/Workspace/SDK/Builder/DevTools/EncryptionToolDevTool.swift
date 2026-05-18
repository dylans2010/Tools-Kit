import SwiftUI
import CryptoKit

struct EncryptionToolImpl: DevTool {
    let id = UUID()
    let name = "Encryption Tool"
    let category: DevToolCategory = .security
    let icon = "lock.rectangle"
    let description = "Encrypt and decrypt text using AES-GCM"
    func render() -> some View { EncryptionToolDevToolView() }
}

struct EncryptionToolDevToolView: View {
    @State private var plaintext = ""
    @State private var passphrase = ""
    @State private var encrypted = ""
    @State private var decrypted = ""
    @State private var errorMsg: String?

    var body: some View {
        Form {
            Section("Plaintext") {
                TextEditor(text: $plaintext).frame(minHeight: 60).font(.system(.body, design: .monospaced))
            }
            Section("Passphrase") {
                SecureField("Enter passphrase", text: $passphrase)
            }
            Section {
                Button("Encrypt") { encrypt() }
                    .disabled(plaintext.isEmpty || passphrase.isEmpty)
                Button("Decrypt") { decrypt() }
                    .disabled(encrypted.isEmpty || passphrase.isEmpty)
            }
            if let errorMsg {
                Section { Label(errorMsg, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            }
            if !encrypted.isEmpty {
                Section("Encrypted (Base64)") {
                    Text(encrypted).font(.system(.caption2, design: .monospaced)).textSelection(.enabled)
                }
            }
            if !decrypted.isEmpty {
                Section("Decrypted") {
                    Text(decrypted).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Encryption Tool")
    }

    private func encrypt() {
        errorMsg = nil
        guard let data = plaintext.data(using: .utf8) else { return }
        let keyData = SHA256.hash(data: passphrase.data(using: .utf8)!)
        let key = SymmetricKey(data: keyData)
        do {
            let sealed = try AES.GCM.seal(data, using: key)
            encrypted = sealed.combined!.base64EncodedString()
        } catch {
            errorMsg = error.localizedDescription
        }
    }

    private func decrypt() {
        errorMsg = nil; decrypted = ""
        guard let combined = Data(base64Encoded: encrypted) else { errorMsg = "Invalid Base64"; return }
        let keyData = SHA256.hash(data: passphrase.data(using: .utf8)!)
        let key = SymmetricKey(data: keyData)
        do {
            let box = try AES.GCM.SealedBox(combined: combined)
            let data = try AES.GCM.open(box, using: key)
            decrypted = String(data: data, encoding: .utf8) ?? "Cannot decode"
        } catch {
            errorMsg = "Decryption failed: \(error.localizedDescription)"
        }
    }
}
