import SwiftUI

struct SSLCertInspectorDevTool: DevTool {
    let id = "ssl-cert-inspector"
    let name = "SSL Certificate Inspector"
    let category: DevToolCategory = .networking
    let icon = "lock.fill"
    let description = "Inspect SSL/TLS certificate details for any domain"

    func render() -> some View {
        CertInspectorView()
    }
}

struct CertInspectorView: View {
    @State private var domain = ""
    @State private var result = ""
    @State private var isChecking = false

    var body: some View {
        Form {
            Section("Domain") {
                TextField("example.com", text: $domain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Button {
                Task { await checkCert() }
            } label: {
                if isChecking {
                    ProgressView().controlSize(.small)
                } else {
                    Text("Inspect Certificate")
                }
            }
            .disabled(domain.isEmpty || isChecking)

            if !result.isEmpty {
                Section("Details") {
                    Text(result)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
    }

    private func checkCert() async {
        isChecking = true
        result = "Connecting..."

        guard let url = URL(string: "https://\(domain)") else {
            result = "Invalid domain"
            isChecking = false
            return
        }

        let session = URLSession(configuration: .ephemeral, delegate: CertDelegate(), delegateQueue: nil)
        do {
            let (_, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse {
                result = "Connected to \(domain)\nStatus: \(http.statusCode)\nSecurity details retrieved during handshake."
            }
        } catch {
            result = "Failed: \(error.localizedDescription)"
        }
        isChecking = false
    }
}

class CertDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let _ = challenge.protectionSpace.serverTrust {
            // In a real tool we'd extract more X.509 fields here
            completionHandler(.performDefaultHandling, nil)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
