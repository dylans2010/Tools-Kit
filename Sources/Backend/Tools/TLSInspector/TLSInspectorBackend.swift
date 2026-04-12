import Foundation
import Security
import CommonCrypto

struct TLSCertificateInfo {
    var subject: String = ""
    var issuer: String = ""
    var validFrom: Date?
    var validTo: Date?
    var sha256Fingerprint: String = ""
    var serialNumber: String = ""
    var isValid: Bool = false
    var daysUntilExpiry: Int = 0

    var expiryStatus: ExpiryStatus {
        if daysUntilExpiry < 0 { return .expired }
        if daysUntilExpiry < 30 { return .expiringSoon }
        return .valid
    }

    enum ExpiryStatus { case valid, expiringSoon, expired }
}

@MainActor
final class TLSInspectorBackend: ObservableObject, @unchecked Sendable {
    @Published var domain = "apple.com"
    @Published var isLoading = false
    @Published var certInfo: TLSCertificateInfo?
    @Published var errorMessage = ""

    func inspect() {
        let trimmed = domain.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        guard !trimmed.isEmpty else { return }

        isLoading = true
        certInfo = nil
        errorMessage = ""

        Task {
            await performInspection(host: trimmed)
        }
    }

    private func performInspection(host: String) async {
        guard let url = URL(string: "https://\(host)") else {
            errorMessage = "Invalid domain"
            isLoading = false
            return
        }

        let delegate = TLSCaptureDelegate()
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "HEAD"

        do {
            _ = try await session.data(for: request)
        } catch {
            // Still might have captured cert info before error
        }

        if let info = delegate.capturedInfo {
            certInfo = info
        } else {
            errorMessage = "Could not retrieve certificate. Check domain."
        }
        isLoading = false
    }
}

private final class TLSCaptureDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    var capturedInfo: TLSCertificateInfo?

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        var info = TLSCertificateInfo()

        if let cert = SecTrustGetCertificateAtIndex(trust, 0) {
            let certData = SecCertificateCopyData(cert) as Data
            let sha = certData.sha256Hex
            info.sha256Fingerprint = sha.chunked(by: 2).joined(separator: ":")

            if let summary = SecCertificateCopySubjectSummary(cert) {
                info.subject = summary as String
            }

            let keys = [kSecOIDX509V1IssuerName, kSecOIDX509V1ValidityNotBefore,
                        kSecOIDX509V1ValidityNotAfter, kSecOIDX509V1SerialNumber] as CFArray
            if let values = SecCertificateCopyValues(cert, keys, nil) as? [String: Any] {
                if let issuerDict = values[kSecOIDX509V1IssuerName as String] as? [String: Any],
                   let issuerVal = issuerDict[kSecPropertyKeyValue as String] as? [[String: Any]] {
                    let parts = issuerVal.compactMap { $0[kSecPropertyKeyValue as String] as? String }
                    info.issuer = parts.joined(separator: ", ")
                }
                if let notBefore = values[kSecOIDX509V1ValidityNotBefore as String] as? [String: Any],
                   let ts = notBefore[kSecPropertyKeyValue as String] as? Double {
                    info.validFrom = Date(timeIntervalSinceReferenceDate: ts)
                }
                if let notAfter = values[kSecOIDX509V1ValidityNotAfter as String] as? [String: Any],
                   let ts = notAfter[kSecPropertyKeyValue as String] as? Double {
                    let expiry = Date(timeIntervalSinceReferenceDate: ts)
                    info.validTo = expiry
                    info.daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
                }
                if let serial = values[kSecOIDX509V1SerialNumber as String] as? [String: Any],
                   let serialVal = serial[kSecPropertyKeyValue as String] as? Data {
                    info.serialNumber = serialVal.hexString
                }
            }

            var result = SecTrustResultType.invalid
            SecTrustEvaluate(trust, &result)
            info.isValid = (result == .unspecified || result == .proceed)
        }

        capturedInfo = info
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}

private extension Data {
    var sha256Hex: String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(count), &digest) }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

private extension String {
    func chunked(by size: Int) -> [String] {
        stride(from: 0, to: count, by: size).map {
            let start = index(startIndex, offsetBy: $0)
            let end = index(start, offsetBy: min(size, count - $0))
            return String(self[start..<end])
        }
    }
}
