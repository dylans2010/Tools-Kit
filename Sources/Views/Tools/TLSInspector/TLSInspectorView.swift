import SwiftUI

struct TLSInspectorTool: Tool, Sendable {
    let name = "TLS Inspector"
    let icon = "lock.shield"
    let category = ToolCategory.network
    let complexity = ToolComplexity.advanced
    let description = "Analyze SSL/TLS certificate details, expiration dates, and trust status for any domain"
    let requiresAPI = false
    var view: AnyView { AnyView(TLSInspectorView()) }
}

struct TLSInspectorView: View {
    @StateObject private var backend = TLSInspectorBackend()

    var body: some View {
        ToolDetailView(tool: TLSInspectorTool()) {
            VStack(spacing: 16) {
                inputSection
                if backend.isLoading {
                    ProgressView("Inspecting Certificate…").padding()
                } else if let info = backend.certInfo {
                    certSection(info)
                } else if !backend.errorMessage.isEmpty {
                    Text(backend.errorMessage)
                        .foregroundColor(.red).font(.subheadline)
                        .padding()
                }
            }
        }
        .navigationTitle("TLS Inspector")
    }

    private var inputSection: some View {
        ToolInputSection("Domain") {
            HStack {
                TextField("apple.com", text: $backend.domain)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                Button("Inspect") { backend.inspect() }
                    .buttonStyle(.borderedProminent)
                    .disabled(backend.isLoading)
            }
            .padding()
        }
    }

    private func certSection(_ info: TLSCertificateInfo) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: info.isValid ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .foregroundColor(info.isValid ? .green : .red)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(info.isValid ? "Certificate Valid" : "Certificate Invalid")
                        .font(.headline)
                    Text(expiryText(info))
                        .font(.caption)
                        .foregroundColor(expiryColor(info))
                }
                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)

            ToolInputSection("Certificate Details") {
                certRow("Subject", value: info.subject)
                Divider()
                certRow("Issuer", value: info.issuer.isEmpty ? "–" : info.issuer)
                Divider()
                if let from = info.validFrom {
                    certRow("Valid From", value: from.formatted(date: .abbreviated, time: .omitted))
                    Divider()
                }
                if let to = info.validTo {
                    certRow("Expires", value: to.formatted(date: .abbreviated, time: .omitted))
                    Divider()
                }
                certRow("Days Until Expiry", value: "\(info.daysUntilExpiry)")
                Divider()
                certRow("Serial #", value: info.serialNumber.isEmpty ? "–" : info.serialNumber)
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("SHA-256 Fingerprint").font(.caption).foregroundColor(.secondary).padding(.horizontal)
                    Text(info.sha256Fingerprint.isEmpty ? "–" : info.sha256Fingerprint)
                        .font(.system(.caption2, design: .monospaced))
                        .padding(.horizontal)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
    }

    private func certRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline).multilineTextAlignment(.trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private func expiryText(_ info: TLSCertificateInfo) -> String {
        switch info.expiryStatus {
        case .expired: return "Certificate Expired"
        case .expiringSoon: return "Expires in \(info.daysUntilExpiry) days"
        case .valid: return "Expires in \(info.daysUntilExpiry) days"
        }
    }

    private func expiryColor(_ info: TLSCertificateInfo) -> Color {
        switch info.expiryStatus {
        case .expired: return .red
        case .expiringSoon: return .orange
        case .valid: return .secondary
        }
    }
}
