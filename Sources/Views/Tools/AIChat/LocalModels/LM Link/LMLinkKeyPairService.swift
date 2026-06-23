import Foundation
import Security
import CryptoKit

final class LMLinkKeyPairService {

    private static let serviceName = "com.toolskit.lmlink.keys"

    enum KeyPairError: Error {
        case storageFailed(OSStatus)
        case notFound
        case decodingFailed
    }

    /// Generates an EC P-256 key pair and stores it in the Keychain.
    /// Returns the keyId and the Base64 encoded raw public key.
    static func generateKeyPair() throws -> (keyId: String, publicKeyBase64: String) {
        let keyId = UUID().uuidString

        // Generate P-256 private key using CryptoKit
        let privateKey = P256.Signing.PrivateKey()
        let privateKeyData = privateKey.rawRepresentation

        // Store raw representation in Keychain using kSecClassGenericPassword
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: keyId,
            kSecValueData as String: privateKeyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            LMLinkLogger.keypair.error("Failed to store P-256 key in Keychain: \(status)")
            throw KeyPairError.storageFailed(status)
        }

        let publicKeyData = privateKey.publicKey.rawRepresentation
        let base64 = publicKeyData.base64EncodedString()

        LMLinkLogger.keypair.info("P-256 key pair generated via CryptoKit. keyId: \(keyId, privacy: .private(mask: .hash))")

        return (keyId: keyId, publicKeyBase64: base64)
    }

    static func loadPrivateKey(for keyId: String) throws -> P256.Signing.PrivateKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: keyId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            LMLinkLogger.keypair.error("Private key not found in Keychain for keyId: \(keyId, privacy: .private(mask: .hash)) status: \(status)")
            throw KeyPairError.notFound
        }

        do {
            return try P256.Signing.PrivateKey(rawRepresentation: data)
        } catch {
            LMLinkLogger.keypair.error("Failed to decode private key for keyId: \(keyId, privacy: .private(mask: .hash))")
            throw KeyPairError.decodingFailed
        }
    }

    static func deleteKeyPair(for keyId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: keyId
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            LMLinkLogger.keypair.error("Failed to delete P-256 key for keyId (status: \(status, privacy: .public))")
        } else {
            LMLinkLogger.keypair.info("P-256 key deleted for keyId: \(keyId, privacy: .private(mask: .hash))")
        }
    }
}
