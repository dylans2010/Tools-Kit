import SwiftUI
import CryptoKit

struct HashGeneratorDevTool: DevTool {
    let id = "hash-generator"
    let name = "Hash Generator"
    let category = DevToolCategory.security
    let icon = "lock.rotation"
    let description = "Generate cryptographic hashes"

    func render() -> some View {
        HashGeneratorDevToolView()
    }
}

struct HashGeneratorDevToolView: View {
    @StateObject private var viewModel = HashGeneratorViewModel()

    var body: some View {
        List {
            Section("Input") {
                ZStack(alignment: .topTrailing) {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 120)
                        .font(.system(.subheadline, design: .monospaced))

                    if !viewModel.input.isEmpty {
                        Button { viewModel.input = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }
                }

                HStack {
                    Button("Paste") {
                        if let s = UIPasteboard.general.string { viewModel.input = s }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Spacer()

                    Text("\(viewModel.input.count) bytes").font(.caption2).foregroundStyle(.secondary)
                }
            }

            Section("Secure Hashes") {
                HashResultRow(title: "SHA-256", value: viewModel.sha256)
                HashResultRow(title: "SHA-512", value: viewModel.sha512)
                HashResultRow(title: "SHA-384", value: viewModel.sha384)
            }

            Section("Legacy / Insecure") {
                HashResultRow(title: "MD5", value: viewModel.md5, color: .orange)
                HashResultRow(title: "SHA-1", value: viewModel.sha1, color: .orange)
            }

            Section("HMAC (Simulated)") {
                TextField("Key", text: $viewModel.hmacKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))

                HashResultRow(title: "HMAC-SHA256", value: viewModel.hmac256)
            }
        }
        .navigationTitle("Hash Generator")
    }
}

struct HashResultRow: View {
    let title: String
    let value: String
    var color: Color = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 10, weight: .black)).foregroundStyle(color)
            HStack {
                Text(value.isEmpty ? "No input" : value)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(value.isEmpty ? .tertiary : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                Spacer()
                if !value.isEmpty {
                    Button {
                        UIPasteboard.general.string = value
                    } label: {
                        Image(systemName: "doc.on.doc").font(.caption)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

class HashGeneratorViewModel: ObservableObject {
    @Published var input = "" {
        didSet { generate() }
    }
    @Published var hmacKey = "" {
        didSet { generate() }
    }

    @Published var sha256 = ""
    @Published var sha512 = ""
    @Published var sha384 = ""
    @Published var md5 = ""
    @Published var sha1 = ""
    @Published var hmac256 = ""

    private func generate() {
        guard let data = input.data(using: .utf8) else {
            sha256 = ""; sha512 = ""; sha384 = ""; md5 = ""; sha1 = ""; hmac256 = ""
            return
        }

        sha256 = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        sha512 = SHA512.hash(data: data).map { String(format: "%02x", $0) }.joined()
        sha384 = SHA384.hash(data: data).map { String(format: "%02x", $0) }.joined()

        md5 = Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
        sha1 = Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()

        if !hmacKey.isEmpty, let keyData = hmacKey.data(using: .utf8) {
            let key = SymmetricKey(data: keyData)
            hmac256 = HMAC<SHA256>.authenticationCode(for: data, using: key).map { String(format: "%02x", $0) }.joined()
        } else {
            hmac256 = ""
        }
    }
}

#Preview {
    HashGeneratorDevToolView()
}
