import Foundation
import Security
import CryptoKit

final class LMLinkKeyPairService {

    enum KeyPairError: Error {
        case generationFailed(OSStatus)
        case notFound
        case exportFailed
        case tagEncodingFailed
    }

    static func generateKeyPair() throws -> (keyId: String, publicKeyBase64: String) {
        let keyId = UUID().uuidString
        guard let tag = "com.toolskit.lmlink.\(keyId)".data(using: .utf8) else {
            throw KeyPairError.tagEncodingFailed
        }
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
        ]
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            LMLinkLogger.keypair.error("Key generation failed: \(error.debugDescription, privacy: .public)")
            throw KeyPairError.generationFailed(errSecParam)
        }
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw KeyPairError.exportFailed
        }
        var exportError: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &exportError) as Data? else {
            throw KeyPairError.exportFailed
        }
        let base64 = publicKeyData.base64EncodedString()
        LMLinkLogger.keypair.info("Key pair generated. keyId: \(keyId, privacy: .private(mask: .hash))")
        return (keyId: keyId, publicKeyBase64: base64)
    }

    static func loadPrivateKey(for keyId: String) throws -> SecKey {
        guard let tag = "com.toolskit.lmlink.\(keyId)".data(using: .utf8) else {
            throw KeyPairError.tagEncodingFailed
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnRef as String: true
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let keyRef = result else {
            LMLinkLogger.keypair.error("Private key not found for keyId: \(keyId, privacy: .private(mask: .hash))")
            throw KeyPairError.notFound
        }
        return keyRef as! SecKey
    }

    static func deleteKeyPair(for keyId: String) {
        guard let tag = "com.toolskit.lmlink.\(keyId)".data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
        ]
        let status = SecItemDelete(query as CFDictionary)
        let publicQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic
        ]
        _ = SecItemDelete(publicQuery as CFDictionary)
        LMLinkLogger.keypair.info("Key pair deleted for keyId (status: \(status, privacy: .public))")
    }
}
