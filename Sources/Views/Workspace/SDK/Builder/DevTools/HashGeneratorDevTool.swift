import SwiftUI
import CryptoKit

struct HashGeneratorTool: DevTool {
    let id = UUID()
    let name = "Hash Generator"
    let category: DevToolCategory = .security
    let icon = "number"
    let description = "Generate MD5, SHA-256, and other hashes"
    func render() -> some View { HashGeneratorDevToolView() }
}

struct HashGeneratorDevToolView: View {
    @State private var input = ""
    @State private var hashes: [(String, String)] = []

    var body: some View {
        Form {
            Section("Input") {
                TextEditor(text: $input)
                    .frame(minHeight: 80)
                    .font(.system(.body, design: .monospaced))
            }
            Section {
                Button("Generate Hashes") { generate() }
                    .disabled(input.isEmpty)
            }
            if !hashes.isEmpty {
                Section("Results") {
                    ForEach(hashes, id: \.0) { name, hash in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name).font(.caption.bold())
                            Text(hash)
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Hash Generator")
    }

    private func generate() {
        guard let data = input.data(using: .utf8) else { return }
        hashes = [
            ("SHA-256", SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()),
            ("SHA-384", SHA384.hash(data: data).map { String(format: "%02x", $0) }.joined()),
            ("SHA-512", SHA512.hash(data: data).map { String(format: "%02x", $0) }.joined()),
            ("MD5", Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()),
            ("SHA-1", Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()),
        ]
    }
}
