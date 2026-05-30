import SwiftUI
import Security

struct CertificateValidatorView: View {
    @State private var certInput = ""
    @State private var resultMessage: String?
    @State private var certInfo: [String: String] = [:]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paste PEM Certificate").font(.headline)
                    TextEditor(text: $certInput)
                        .font(.system(.caption, design: .monospaced))
                        .frame(height: 150)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }

                Button("Inspect Certificate") {
                    inspect()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                if let msg = resultMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if !certInfo.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Certificate Details").font(.headline)

                        VStack(spacing: 1) {
                            ForEach(certInfo.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                HStack {
                                    Text(key).font(.caption.bold())
                                    Spacer()
                                    Text(value).font(.caption).foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.1)))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Cert Validator")
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func inspect() {
        certInfo = [:]
        resultMessage = nil

        let cleaned = certInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty {
            resultMessage = "Please paste a certificate"
            return
        }

        if !cleaned.contains("BEGIN CERTIFICATE") {
            resultMessage = "Invalid format: Missing BEGIN CERTIFICATE header"
            return
        }

        // Basic parser for PEM content to extract metadata
        certInfo["Type"] = "X.509"
        certInfo["Format"] = "PEM"

        let lines = cleaned.components(separatedBy: .newlines)
        let body = lines.filter { !$0.contains("CERTIFICATE") }.joined()

        if let data = Data(base64Encoded: body) {
            certInfo["Size"] = "\(data.count) bytes"
            certInfo["Status"] = "Parsed successfully"

            // In a real app we would use SecCertificateCreateWithData
            if let cert = SecCertificateCreateWithData(nil, data as CFData) {
                certInfo["Summary"] = SecCertificateCopySubjectSummary(cert) as String? ?? "Unknown"
            }
        } else {
            resultMessage = "Failed to decode base64 certificate body"
        }
    }
}
