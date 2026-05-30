import SwiftUI
import CryptoKit

struct DeveloperHashGeneratorView: View {
    @State private var inputText = ""
    @State private var sha256Hash = ""
    @State private var sha512Hash = ""
    @State private var md5Hash = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Input Text").font(.headline)
                    TextEditor(text: $inputText)
                        .font(.system(.subheadline, design: .monospaced))
                        .frame(height: 120)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                        .onChange(of: inputText) { _ in generateHashes() }
                }

                VStack(alignment: .leading, spacing: 16) {
                    hashResultRow(label: "SHA-256", value: sha256Hash)
                    hashResultRow(label: "SHA-512", value: sha512Hash)
                    hashResultRow(label: "MD5", value: md5Hash)
                }
            }
            .padding()
        }
        .navigationTitle("Hash Generator")
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func hashResultRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label).font(.subheadline.bold())
                Spacer()
                if !value.isEmpty {
                    Button {
                        UIPasteboard.general.string = value
                    } label: {
                        Image(systemName: "doc.on.doc").font(.caption)
                    }
                }
            }

            Text(value.isEmpty ? "No input" : value)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.1)))
        }
    }

    private func generateHashes() {
        guard !inputText.isEmpty, let data = inputText.data(using: .utf8) else {
            sha256Hash = ""
            sha512Hash = ""
            md5Hash = ""
            return
        }

        sha256Hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        sha512Hash = SHA512.hash(data: data).map { String(format: "%02x", $0) }.joined()

        // MD5 is not in CryptoKit but we can use Insecure.MD5
        md5Hash = Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
