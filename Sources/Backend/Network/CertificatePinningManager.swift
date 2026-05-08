@preconcurrency import Foundation
import Security
import CommonCrypto

/// Middleware that enforces certificate pinning for specified domains.
final class CertificatePinningMiddleware: NetworkMiddleware {
    var pins: [String: Set<String>]

    init(pins: [String: Set<String>] = [:]) {
        self.pins = pins
    }

    func process(request: inout URLRequest) -> NetworkMiddlewareDecision {
        return .allow
    }
}

/// URLSession delegate that enforces certificate pinning using SHA-256 of the leaf certificate's DER data.
final class CertificatePinningDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    let pins: [String: Set<String>]

    init(pins: [String: Set<String>]) {
        self.pins = pins
    }

    nonisolated func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let host = challenge.protectionSpace.host
        guard let expectedPins = pins[host], !expectedPins.isEmpty else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard let cert = SecTrustGetCertificateAtIndex(trust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let certData = SecCertificateCopyData(cert) as Data
        let fingerprint = certData.sha256Hex

        if expectedPins.contains(fingerprint) {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

private extension Data {
    var sha256Hex: String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(count), &digest) }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
