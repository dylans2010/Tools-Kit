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
        Form {
            Section("Input Content") {
                TextEditor(text: $viewModel.input)
                    .frame(height: 100)
            }

            Section("Algorithms") {
                VStack(alignment: .leading, spacing: 12) {
                    hashRow(title: "SHA-256", value: viewModel.sha256)
                    hashRow(title: "SHA-512", value: viewModel.sha512)
                    hashRow(title: "MD5", value: viewModel.md5)
                }
            }
        }
    }

    private func hashRow(title: String, value: String) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption.bold()).foregroundStyle(Color.accentColor)
            HStack {
                Text(value)
                    .font(.system(.caption2, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                Spacer()
                Button {
                    UIPasteboard.general.string = value
                } label: {
                    Image(systemName: "doc.on.doc").font(.caption)
                }
            }
        }
    }
}

class HashGeneratorViewModel: ObservableObject {
    @Published var input = "" {
        didSet { generate() }
    }
    @Published var sha256 = ""
    @Published var sha512 = ""
    @Published var md5 = ""

    private func generate() {
        guard let data = input.data(using: .utf8) else { return }

        let s256 = SHA256.hash(data: data)
        sha256 = s256.map { String(format: "%02x", $0) }.joined()

        let s512 = SHA512.hash(data: data)
        sha512 = s512.map { String(format: "%02x", $0) }.joined()

        // Simple Insecure MD5 (using Apple CryptoKit doesn't support MD5 directly for security reasons,
        // but we can mock it or use a library. For this tool we will use Insecure.MD5)
        let m5 = Insecure.MD5.hash(data: data)
        md5 = m5.map { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    HashGeneratorDevToolView()
}
