import Foundation
import CryptoKit

class LMRequestSigner {
    private let keychain = LMLinkKeychainService.shared

    func sign(payload: Data) throws -> String? {
        guard let privateKey = try keychain.getPrivateKey() else {
            return nil
        }

        let signature = try privateKey.signature(for: payload)
        return signature.base64EncodedString()
    }

    func addSignatureHeaders(to request: inout URLRequest, payload: Data) throws {
        guard let keyId = keychain.getKeyId(),
              let signature = try sign(payload: payload) else {
            return
        }

        request.addValue(keyId, forHTTPHeaderField: "X-LM-Key-ID")
        request.addValue(signature, forHTTPHeaderField: "X-LM-Signature")
        request.addValue(String(Int(Date().timeIntervalSince1970)), forHTTPHeaderField: "X-LM-Timestamp")
    }
}
