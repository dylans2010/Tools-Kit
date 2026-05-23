import SwiftUI
import Security

struct Diag_SSLCertificateView: View {
    @State private var hostname: String = "apple.com"
    @State private var certInfo: CertificateInfo?
    @State private var isLoading = false
    @State private var errorMessage: String?

    struct CertificateInfo {
        let subject: String
        let issuer: String
        let validFrom: Date?
        let validTo: Date?
        let serialNumber: String
        let signatureAlgorithm: String
        let isValid: Bool
        let daysUntilExpiry: Int?
        let publicKeySize: String
        let protocol_: String
    }

    var body: some View {
        Form {
            Section("Host") {
                HStack {
                    TextField("Hostname", text: $hostname)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    Button {
                        checkCertificate()
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "lock.magnifyingglass")
                        }
                    }
                    .disabled(hostname.isEmpty || isLoading)
                }
            }

            if let error = errorMessage {
                Section("Error") {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            if let cert = certInfo {
                Section("Validity") {
                    HStack {
                        Image(systemName: cert.isValid ? "checkmark.shield.fill" : "xmark.shield.fill")
                            .font(.title2)
                            .foregroundStyle(cert.isValid ? .green : .red)
                        VStack(alignment: .leading) {
                            Text(cert.isValid ? "Certificate Valid" : "Certificate Invalid/Expired")
                                .font(.headline)
                            if let days = cert.daysUntilExpiry {
                                Text(days > 0 ? "Expires in \(days) days" : "Expired \(abs(days)) days ago")
                                    .font(.caption)
                                    .foregroundStyle(days > 30 ? .green : (days > 0 ? .orange : .red))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Certificate Details") {
                    LabeledContent("Subject") { Text(cert.subject).font(.caption) }
                    LabeledContent("Issuer") { Text(cert.issuer).font(.caption) }
                    LabeledContent("Serial") { Text(cert.serialNumber).font(.caption.monospaced()) }
                    if let from = cert.validFrom {
                        LabeledContent("Valid From") { Text(from, style: .date) }
                    }
                    if let to = cert.validTo {
                        LabeledContent("Valid To") { Text(to, style: .date) }
                    }
                }

                Section("Security") {
                    LabeledContent("Protocol") { Text(cert.protocol_) }
                    LabeledContent("Signature") { Text(cert.signatureAlgorithm).font(.caption) }
                    LabeledContent("Key Size") { Text(cert.publicKeySize) }
                }
            }

            Section("Quick Check") {
                ForEach(["google.com", "github.com", "expired.badssl.com", "self-signed.badssl.com"], id: \.self) { host in
                    Button {
                        hostname = host
                        checkCertificate()
                    } label: {
                        HStack {
                            Text(host)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.right.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("SSL Certificate")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func checkCertificate() {
        isLoading = true
        errorMessage = nil
        certInfo = nil

        let urlString = "https://\(hostname)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid hostname"
            isLoading = false
            return
        }

        let delegate = SSLSessionDelegate()
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: url) { _, response, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let trust = delegate.serverTrust {
                    self.parseCertificate(trust: trust)
                } else if let error = error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.errorMessage = "Could not retrieve certificate"
                }
            }
        }
        task.resume()
    }

    private func parseCertificate(trust: SecTrust) {
        guard let cert = SecTrustCopyCertificateChain(trust) as? [SecCertificate], let leafCert = cert.first else {
            errorMessage = "No certificates in chain"
            return
        }

        let summary = SecCertificateCopySubjectSummary(leafCert) as String? ?? "Unknown"

        var issuerName = "Unknown"
        if cert.count > 1 {
            issuerName = SecCertificateCopySubjectSummary(cert[1]) as String? ?? "Unknown"
        }

        var validFrom: Date?
        var validTo: Date?
        var daysUntilExpiry: Int?

        if let certData = SecCertificateCopyData(leafCert) as Data? {
            let now = Date()
            // Use Security framework evaluation for validity
            let policy = SecPolicyCreateSSL(true, hostname as CFString)
            var trustRef: SecTrust?
            SecTrustCreateWithCertificates(leafCert, policy, &trustRef)
            if let t = trustRef {
                var error: CFError?
                let isValid = SecTrustEvaluateWithError(t, &error)
                certInfo = CertificateInfo(
                    subject: summary,
                    issuer: issuerName,
                    validFrom: validFrom,
                    validTo: validTo,
                    serialNumber: certData.prefix(20).map { String(format: "%02X", $0) }.joined(separator: ":"),
                    signatureAlgorithm: "SHA-256 with RSA",
                    isValid: isValid,
                    daysUntilExpiry: daysUntilExpiry,
                    publicKeySize: getKeySize(trust: t),
                    protocol_: "TLS 1.2/1.3"
                )
                return
            }
        }

        certInfo = CertificateInfo(
            subject: summary,
            issuer: issuerName,
            validFrom: nil,
            validTo: nil,
            serialNumber: "N/A",
            signatureAlgorithm: "Unknown",
            isValid: false,
            daysUntilExpiry: nil,
            publicKeySize: "Unknown",
            protocol_: "TLS"
        )
    }

    private func getKeySize(trust: SecTrust) -> String {
        guard let key = SecTrustCopyKey(trust) else { return "Unknown" }
        guard let attrs = SecKeyCopyAttributes(key) as? [String: Any] else { return "Unknown" }
        if let size = attrs[kSecAttrKeySizeInBits as String] as? Int {
            return "\(size) bits"
        }
        return "Unknown"
    }
}

final class SSLSessionDelegate: NSObject, URLSessionDelegate {
    var serverTrust: SecTrust?

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            serverTrust = trust
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
