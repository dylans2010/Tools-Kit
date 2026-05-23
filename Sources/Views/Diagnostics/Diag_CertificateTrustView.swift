import SwiftUI
import Security

struct Diag_CertificateTrustView: View {
    @State private var certificates: [CertInfo] = []
    @State private var isLoading = true
    @State private var stats: [(String, String)] = []

    struct CertInfo: Identifiable {
        let id = UUID()
        let label: String
        let issuer: String
        let serialNumber: String
        let isTrusted: Bool
    }

    var body: some View {
        Form {
            Section("Certificate Trust Store") {
                VStack(spacing: 8) {
                    Image(systemName: "lock.doc.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Certificate Inspector")
                        .font(.headline)
                    Text("View installed certificates and trust settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Trust Store Statistics") {
                if isLoading {
                    ProgressView("Scanning certificates...")
                } else {
                    ForEach(stats, id: \.0) { stat in
                        LabeledContent(stat.0) {
                            Text(stat.1)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !certificates.isEmpty {
                Section("Keychain Certificates (\(certificates.count))") {
                    ForEach(certificates) { cert in
                        HStack {
                            Image(systemName: cert.isTrusted ? "checkmark.seal.fill" : "xmark.seal.fill")
                                .foregroundStyle(cert.isTrusted ? .green : .red)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cert.label)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                Text(cert.issuer)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }

            Section("SSL/TLS Connection Test") {
                Button {
                    testSSLConnection()
                } label: {
                    HStack {
                        Image(systemName: "lock.fill")
                        Text("Test SSL to apple.com")
                    }
                }
            }

            Section("About Trust Store") {
                Text("iOS maintains a pre-installed set of trusted root certificates. Apps and services use these to verify SSL/TLS connections. Custom certificates can be installed via profiles.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    scanCertificates()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Rescan")
                    }
                }
            }
        }
        .navigationTitle("Certificate Trust")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { scanCertificates() }
    }

    private func scanCertificates() {
        isLoading = true

        let query: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
            kSecReturnRef as String: true
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        var certs: [CertInfo] = []
        var totalCount = 0
        var trustedCount = 0

        if status == errSecSuccess, let items = result as? [[String: Any]] {
            totalCount = items.count
            for item in items {
                let label = (item[kSecAttrLabel as String] as? String) ?? "Unknown Certificate"
                let issuer = (item[kSecAttrIssuer as String] as? Data).flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown Issuer"
                let serial = (item[kSecAttrSerialNumber as String] as? Data)?.map { String(format: "%02X", $0) }.joined(separator: ":") ?? "N/A"

                var isTrusted = true
                if let certRef = item[kSecValueRef as String] {
                    let cert = certRef as! SecCertificate
                    var trust: SecTrust?
                    let policy = SecPolicyCreateBasicX509()
                    if SecTrustCreateWithCertificates(cert, policy, &trust) == errSecSuccess, let trust = trust {
                        var error: CFError?
                        isTrusted = SecTrustEvaluateWithError(trust, &error)
                    }
                }

                if isTrusted { trustedCount += 1 }
                certs.append(CertInfo(label: label, issuer: issuer, serialNumber: serial, isTrusted: isTrusted))
            }
        }

        certificates = certs
        stats = [
            ("Total Certificates", "\(totalCount)"),
            ("Trusted", "\(trustedCount)"),
            ("Untrusted", "\(totalCount - trustedCount)"),
            ("Keychain Status", status == errSecSuccess ? "Accessible" : "Error: \(status)")
        ]
        isLoading = false
    }

    private func testSSLConnection() {
        guard let url = URL(string: "https://www.apple.com") else { return }
        URLSession.shared.dataTask(with: url) { _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    stats.append(("SSL Test (apple.com)", "Status: \(httpResponse.statusCode) — Connection secure"))
                } else if let error = error {
                    stats.append(("SSL Test (apple.com)", "Failed: \(error.localizedDescription)"))
                }
            }
        }.resume()
    }
}
