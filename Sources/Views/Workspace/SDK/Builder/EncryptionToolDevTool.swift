import SwiftUI
import CryptoKit

struct EncryptionToolDevTool: DevTool {
    let id = "encryption-tool"
    let name = "Encryption Tool"
    let category = DevToolCategory.security
    let icon = "key.fill"
    let description = "Encrypt and decrypt with AES-GCM, key management, and password derivation"

    func render() -> some View {
        EncryptionToolView()
    }
}

struct EncryptionToolView: View {
    @StateObject private var viewModel = EncryptionToolViewModel()

    var body: some View {
        Form {
            Section(header: Text("Key Configuration")) {
                Picker("Key Source", selection: $viewModel.keySource) {
                    Text("Password").tag(EncryptKeySource.password)
                    Text("Base64 Key").tag(EncryptKeySource.base64)
                    Text("Generated").tag(EncryptKeySource.generated)
                }
                .pickerStyle(.segmented)

                if viewModel.keySource == .password {
                    SecureField("Password", text: $viewModel.password)
                    HStack {
                        Text("Key Derivation")
                        Spacer()
                        Text("HKDF-SHA256")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if viewModel.keySource == .base64 {
                    TextField("Base64 Key", text: $viewModel.key)
                        .font(.system(.caption, design: .monospaced))
                        .textInputAutocapitalization(.never)
                }

                HStack {
                    Picker("Key Size", selection: $viewModel.keySizeBits) {
                        Text("128-bit").tag(128)
                        Text("256-bit").tag(256)
                    }

                    Button("Generate Key") { viewModel.generateKey() }
                        .buttonStyle(.bordered).controlSize(.small)
                }
            }

            Section(header: Text("Encryption")) {
                Picker("Algorithm", selection: $viewModel.algorithm) {
                    Text("AES-GCM").tag(EncryptAlgorithm.aesGCM)
                    Text("ChaChaPoly").tag(EncryptAlgorithm.chaChaPoly)
                }
                .pickerStyle(.segmented)
            }

            Section(header: Text("Input")) {
                TextEditor(text: $viewModel.input)
                    .frame(height: 100)
                    .font(.system(.caption, design: .monospaced))
                HStack {
                    Button("Paste") {
                        if let text = UIPasteboard.general.string { viewModel.input = text }
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                    Button("Clear") { viewModel.input = ""; viewModel.output = "" }
                        .buttonStyle(.bordered).controlSize(.small)
                }
            }

            Section(header: Text("Actions")) {
                HStack(spacing: 12) {
                    Button {
                        viewModel.encrypt()
                    } label: {
                        Label("Encrypt", systemImage: "lock.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        viewModel.decrypt()
                    } label: {
                        Label("Decrypt", systemImage: "lock.open.fill")
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section(header: Text("Output")) {
                if !viewModel.output.isEmpty {
                    Text(viewModel.output)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(minHeight: 60)

                    HStack {
                        Button {
                            UIPasteboard.general.string = viewModel.output
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered).controlSize(.small)

                        Spacer()
                        Text("\(viewModel.output.count) chars")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if !viewModel.error.isEmpty {
                    Label(viewModel.error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section(header: Text("Key Info")) {
                if !viewModel.activeKeyBase64.isEmpty {
                    HStack {
                        Text("Active Key (Base64)")
                        Spacer()
                        Text(viewModel.activeKeyBase64)
                            .font(.caption2.monospaced())
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Button {
                        UIPasteboard.general.string = viewModel.activeKeyBase64
                    } label: {
                        Label("Copy Key", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                }
            }
        }
    }
}

enum EncryptKeySource: Hashable { case password, base64, generated }
enum EncryptAlgorithm: Hashable { case aesGCM, chaChaPoly }

class EncryptionToolViewModel: ObservableObject {
    @Published var keySource = EncryptKeySource.password
    @Published var password = "my-secret-password"
    @Published var key = ""
    @Published var keySizeBits = 256

    private var keyByteSize: Int {
        keySizeBits / 8
    }
    @Published var algorithm = EncryptAlgorithm.aesGCM
    @Published var input = "Sensitive data"
    @Published var output = ""
    @Published var error = ""
    @Published var activeKeyBase64 = ""

    func generateKey() {
        let newKey = SymmetricKey(size: keySizeBits == 128 ? .bits128 : .bits256)
        key = newKey.withUnsafeBytes { Data($0).base64EncodedString() }
        keySource = .base64
        activeKeyBase64 = key
    }

    private func deriveKey() -> SymmetricKey? {
        switch keySource {
        case .password:
            guard let passData = password.data(using: .utf8), !password.isEmpty else { return nil }
            let derived = HKDF<SHA256>.deriveKey(
                inputKeyMaterial: SymmetricKey(data: passData),
                salt: Data(),
                info: Data(),
                outputByteCount: keyByteSize
            )
            activeKeyBase64 = derived.withUnsafeBytes { Data($0).base64EncodedString() }
            return derived
        case .base64:
            guard let keyData = Data(base64Encoded: key) else { return nil }
            let symKey = SymmetricKey(data: keyData)
            activeKeyBase64 = key
            return symKey
        case .generated:
            let newKey = SymmetricKey(size: keySizeBits == 128 ? .bits128 : .bits256)
            activeKeyBase64 = newKey.withUnsafeBytes { Data($0).base64EncodedString() }
            return newKey
        }
    }

    func encrypt() {
        error = ""
        guard let data = input.data(using: .utf8) else { error = "Invalid input"; return }
        guard let symmetricKey = deriveKey() else { error = "Invalid key"; return }

        do {
            switch algorithm {
            case .aesGCM:
                let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
                output = sealedBox.combined?.base64EncodedString() ?? ""
            case .chaChaPoly:
                let sealedBox = try ChaChaPoly.seal(data, using: symmetricKey)
                output = sealedBox.combined.base64EncodedString()
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func decrypt() {
        error = ""
        guard let combinedData = Data(base64Encoded: input) else { error = "Invalid Base64 data"; return }
        guard let symmetricKey = deriveKey() else { error = "Invalid key"; return }

        do {
            let decryptedData: Data
            switch algorithm {
            case .aesGCM:
                let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
                decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            case .chaChaPoly:
                let sealedBox = try ChaChaPoly.SealedBox(combined: combinedData)
                decryptedData = try ChaChaPoly.open(sealedBox, using: symmetricKey)
            }
            output = String(data: decryptedData, encoding: .utf8) ?? "Decrypted data is not UTF-8"
        } catch {
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    EncryptionToolView()
}
