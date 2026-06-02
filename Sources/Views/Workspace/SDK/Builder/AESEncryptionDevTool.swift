import SwiftUI
import CryptoKit

struct AESEncryptionDevTool: DevTool {
    let id = "aes-encryption"
    let name = "AES Encryption/Decryption"
    let category: DevToolCategory = .security
    let icon = "lock.shield"
    let description = "Encrypt and decrypt text using AES-GCM (256-bit)"

    func render() -> some View {
        AESEncryptionView()
    }
}

struct AESEncryptionView: View {
    @State private var keyString = "01234567890123456789012345678901" // 32 bytes for AES-256
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var mode: AESMode = .encrypt

    enum AESMode { case encrypt, decrypt }

    var body: some View {
        Form {
            Section("Configuration") {
                TextField("Key (32 characters)", text: $keyString)
                    .font(.system(.caption, design: .monospaced))
                Picker("Mode", selection: $mode) {
                    Text("Encrypt").tag(AESMode.encrypt)
                    Text("Decrypt").tag(AESMode.decrypt)
                }.pickerStyle(.segmented)
            }

            Section("Input") {
                TextEditor(text: $inputText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 100)
            }

            Button {
                process()
            } label: {
                Label(mode == .encrypt ? "Encrypt" : "Decrypt", systemImage: mode == .encrypt ? "lock.fill" : "lock.open.fill")
                    .frame(maxWidth: .infinity)
            }.buttonStyle(.borderedProminent)

            if !outputText.isEmpty {
                Section("Output") {
                    Text(outputText)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)

                    Button("Copy Output") {
                        #if os(iOS)
                        UIPasteboard.general.string = outputText
                        #elseif os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(outputText, forType: .string)
                        #endif
                    }
                }
            }
        }
    }

    private func process() {
        guard let keyData = keyString.data(using: .utf8), keyData.count == 32 else {
            outputText = "Error: Key must be exactly 32 bytes (256-bit)"
            return
        }
        let key = SymmetricKey(data: keyData)

        if mode == .encrypt {
            guard let data = inputText.data(using: .utf8) else { return }
            do {
                let sealedBox = try AES.GCM.seal(data, using: key)
                outputText = sealedBox.combined?.base64EncodedString() ?? "Encryption failed"
            } catch {
                outputText = "Error: \(error.localizedDescription)"
            }
        } else {
            guard let data = Data(base64Encoded: inputText) else {
                outputText = "Error: Invalid Base64 input"
                return
            }
            do {
                let sealedBox = try AES.GCM.SealedBox(combined: data)
                let decryptedData = try AES.GCM.open(sealedBox, using: key)
                outputText = String(data: decryptedData, encoding: .utf8) ?? "Decryption failed (encoding error)"
            } catch {
                outputText = "Error: \(error.localizedDescription)"
            }
        }
    }
}
