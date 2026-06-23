import Foundation
import Security

class LMRequestSigner {
    private let keychain = LMLinkKeychainService()

    func sign(payload: Data, keyId: String) throws -> String? {
        let privateKey = try LMLinkKeyPairService.loadPrivateKey(for: keyId)

        var error: Unmanaged<CFError>?
        // Using .edSignature for Ed25519 (Curve25519) keys
        guard let signature = SecKeyCreateSignature(privateKey, .edSignature, payload as CFData, &error) as Data? else {
            LMLinkLogger.keypair.error("Ed25519 Signing failed: \(error.debugDescription, privacy: .public)")
            return nil
        }

        return signature.base64EncodedString()
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
