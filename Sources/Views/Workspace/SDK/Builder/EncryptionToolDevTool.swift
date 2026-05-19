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
    @State private var showingKey = false

    var body: some View {
        List {
            Section("Vault Key") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        if showingKey {
                            TextField("Key (Base64)", text: $viewModel.key)
                                .font(.system(.caption2, design: .monospaced))
                        } else {
                            SecureField("Key (Base64)", text: $viewModel.key)
                        }

                        Button { showingKey.toggle() } label: {
                            Image(systemName: showingKey ? "eye.slash" : "eye")
                        }
                    }

                    HStack {
                        Button("Generate Key") { viewModel.generateKey() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                        Spacer()

                        Button("Paste Key") {
                            if let s = UIPasteboard.general.string { viewModel.key = s }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Data Buffer") {
                ZStack(alignment: .topTrailing) {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 120)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(4)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    if !viewModel.input.isEmpty {
                        Button { viewModel.input = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }
                }

                HStack(spacing: 16) {
                    Button { viewModel.encrypt() } label: {
                        Label("Encrypt", systemImage: "lock.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button { viewModel.decrypt() } label: {
                        Label("Decrypt", systemImage: "lock.open.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }

            if !viewModel.output.isEmpty || !viewModel.error.isEmpty {
                Section("Ciphertext / Plaintext") {
                    VStack(alignment: .leading, spacing: 8) {
                        if !viewModel.error.isEmpty {
                            Label(viewModel.error, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption2.bold())
                                .foregroundStyle(.red)
                        } else {
                            Text(viewModel.output)
                                .font(.system(size: 10, design: .monospaced))
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.green.opacity(0.05))
                                .cornerRadius(8)
                                .textSelection(.enabled)

                            HStack {
                                Button("Copy Result") { UIPasteboard.general.string = viewModel.output }
                                Spacer()
                                Button("Clear") { viewModel.output = "" }
                            }
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("AES GCM Lab")
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
