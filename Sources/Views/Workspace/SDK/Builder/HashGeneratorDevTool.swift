import SwiftUI
import CryptoKit

struct HashGeneratorDevTool: DevTool {
    let id = "hash-generator"
    let name = "Hash Generator"
    let category = DevToolCategory.security
    let icon = "lock.rotation"
    let description = "Generate and compare cryptographic hashes"

    func render() -> some View {
        HashGeneratorDevToolView()
    }
}

struct HashGeneratorDevToolView: View {
    @StateObject private var viewModel = HashGeneratorViewModel()

    var body: some View {
        Form {
            Section(header: Text("Input Content")) {
                TextEditor(text: $viewModel.input)
                    .frame(height: 100)
                HStack {
                    Button("Paste") {
                        if let text = UIPasteboard.general.string { viewModel.input = text }
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                    Button("Clear") { viewModel.input = "" }
                        .buttonStyle(.bordered).controlSize(.small)
                }
            }

            Section(header: Text("Encoding")) {
                Picker("Input Encoding", selection: $viewModel.encoding) {
                    Text("UTF-8").tag(HashEncoding.utf8)
                    Text("ASCII").tag(HashEncoding.ascii)
                    Text("Hex").tag(HashEncoding.hex)
                }
                .pickerStyle(.segmented)

                Picker("Output Format", selection: $viewModel.outputFormat) {
                    Text("Hex").tag(HashOutputFormat.hex)
                    Text("Base64").tag(HashOutputFormat.base64)
                    Text("Uppercase Hex").tag(HashOutputFormat.upperHex)
                }
            }

            Section(header: Text("Hash Results")) {
                VStack(alignment: .leading, spacing: 12) {
                    hashRow(title: "SHA-256", value: viewModel.sha256)
                    hashRow(title: "SHA-384", value: viewModel.sha384)
                    hashRow(title: "SHA-512", value: viewModel.sha512)
                    hashRow(title: "MD5", value: viewModel.md5)
                }
            }

            Section(header: Text("HMAC")) {
                SecureField("HMAC Key", text: $viewModel.hmacKey)
                if !viewModel.hmacKey.isEmpty {
                    hashRow(title: "HMAC-SHA256", value: viewModel.hmacSha256)
                }
            }

            Section(header: Text("Hash Comparison")) {
                TextField("Paste hash to compare", text: $viewModel.compareHash)
                    .font(.system(.caption, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !viewModel.compareHash.isEmpty {
                    HStack {
                        Image(systemName: viewModel.compareResult ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(viewModel.compareResult ? .green : .red)
                        Text(viewModel.compareResult ? "Hash matches SHA-256 output" : "No match found")
                            .font(.caption)
                    }
                }
            }

            Section(header: Text("Statistics")) {
                LabeledContent("Input length", value: "\(viewModel.input.count) chars")
                LabeledContent("Byte count", value: "\(viewModel.input.data(using: .utf8)?.count ?? 0) bytes")
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

enum HashEncoding {
    case utf8, ascii, hex
}

enum HashOutputFormat {
    case hex, base64, upperHex
}

class HashGeneratorViewModel: ObservableObject {
    @Published var input = "" { didSet { generate() } }
    @Published var encoding = HashEncoding.utf8 { didSet { generate() } }
    @Published var outputFormat = HashOutputFormat.hex { didSet { generate() } }
    @Published var hmacKey = "" { didSet { generate() } }
    @Published var compareHash = "" { didSet { compare() } }

    @Published var sha256 = ""
    @Published var sha384 = ""
    @Published var sha512 = ""
    @Published var md5 = ""
    @Published var hmacSha256 = ""
    @Published var compareResult = false

    private func inputData() -> Data? {
        switch encoding {
        case .utf8: return input.data(using: .utf8)
        case .ascii: return input.data(using: .ascii)
        case .hex:
            var data = Data()
            var hex = input.replacingOccurrences(of: " ", with: "")
            while hex.count >= 2 {
                let byteStr = String(hex.prefix(2))
                hex = String(hex.dropFirst(2))
                guard let byte = UInt8(byteStr, radix: 16) else { return nil }
                data.append(byte)
            }
            return data
        }
    }

    private func format<H: HashFunction>(_ digest: H.Digest, _ type: H.Type) -> String {
        switch outputFormat {
        case .hex: return digest.map { String(format: "%02x", $0) }.joined()
        case .upperHex: return digest.map { String(format: "%02X", $0) }.joined()
        case .base64: return Data(digest).base64EncodedString()
        }
    }

    private func formatInsecure(_ digest: Insecure.MD5.Digest) -> String {
        switch outputFormat {
        case .hex: return digest.map { String(format: "%02x", $0) }.joined()
        case .upperHex: return digest.map { String(format: "%02X", $0) }.joined()
        case .base64: return Data(digest).base64EncodedString()
        }
    }

    private func generate() {
        guard let data = inputData() else { return }

        sha256 = format(SHA256.hash(data: data), SHA256.self)
        sha384 = format(SHA384.hash(data: data), SHA384.self)
        sha512 = format(SHA512.hash(data: data), SHA512.self)
        md5 = formatInsecure(Insecure.MD5.hash(data: data))

        if let keyData = hmacKey.data(using: .utf8), !hmacKey.isEmpty {
            let key = SymmetricKey(data: keyData)
            let mac = HMAC<SHA256>.authenticationCode(for: data, using: key)
            switch outputFormat {
            case .hex: hmacSha256 = Data(mac).map { String(format: "%02x", $0) }.joined()
            case .upperHex: hmacSha256 = Data(mac).map { String(format: "%02X", $0) }.joined()
            case .base64: hmacSha256 = Data(mac).base64EncodedString()
            }
        } else {
            hmacSha256 = ""
        }
        compare()
    }

    private func compare() {
        let normalized = compareHash.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        compareResult = !normalized.isEmpty && (normalized == sha256.lowercased() || normalized == sha512.lowercased() || normalized == md5.lowercased() || normalized == sha384.lowercased())
    }
}

#Preview {
    HashGeneratorDevToolView()
}
