import Foundation
import Security
import CryptoKit

class LMRequestSigner {
    private let keychain = LMLinkKeychainService()

    func sign(payload: Data, keyId: String) throws -> String? {
        let privateKey = try LMLinkKeyPairService.loadPrivateKey(for: keyId)

        do {
            let signature = try privateKey.signature(for: payload)
            return signature.base64EncodedString()
        } catch {
            LMLinkLogger.keypair.error("Ed25519 Signing failed via CryptoKit: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func addSignatureHeaders(to request: inout URLRequest, payload: Data) throws {
        // We need the keyId to load the private key.
        let result = keychain.load()
        guard case .success(let session) = result else {
            return
        }

        guard let signature = try sign(payload: payload, keyId: session.keyId) else {
            return
        }

        request.addValue(session.keyId, forHTTPHeaderField: "X-LM-Key-ID")
        request.addValue(signature, forHTTPHeaderField: "X-LM-Signature")
        request.addValue(String(Int(Date().timeIntervalSince1970)), forHTTPHeaderField: "X-LM-Timestamp")
    }
}
