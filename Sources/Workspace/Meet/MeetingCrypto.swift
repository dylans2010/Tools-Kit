/*
 * Summary: AES-256-GCM encryption service for Meeting IDs.
 * Changes: Implemented secure encryption/decryption, Keychain key persistence,
 *          Base64URL encoding, and removed force-unwraps.
 */

import Foundation
import CryptoKit
import Security

/// Service for encrypting and decrypting Meeting IDs.
public enum MeetingCrypto {
    private static let serviceName = "com.app.meet.encryptionKey"
    private static let prefix = "Meeting-"

    enum CryptoError: Error {
        case keyGenerationFailed
        case keyNotFound
        case encryptionFailed
        case decryptionFailed
        case invalidCiphertext
        case invalidPlaintext
        case storageFailed
    }

    /// Encrypts a raw Daily room name into a Base64URL-encoded ciphertext.
    public static func encryptMeetingID(_ rawID: String) throws -> String {
        let key = try getOrCreateKey()
        let plaintext = prefix + rawID
        guard let data = plaintext.data(using: .utf8) else {
            throw CryptoError.invalidPlaintext
        }

        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else {
                throw CryptoError.encryptionFailed
            }

            #if DEBUG
            MeetingLogger.debug("Encrypted meeting ID: \(rawID)", category: MeetingLogger.crypto)
            #endif

            return combined.base64URLEncodedString()
        } catch {
            MeetingLogger.error("Encryption failed: \(error.localizedDescription)", category: MeetingLogger.crypto)
            throw CryptoError.encryptionFailed
        }
    }

    /// Decrypts a Base64URL-encoded ciphertext back into the original raw Daily room name.
    public static func decryptMeetingID(_ ciphertext: String) throws -> String {
        let key = try getOrCreateKey()

        guard let data = Data(base64URLSafeString: ciphertext) else {
            throw CryptoError.invalidCiphertext
        }

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)

            guard let plaintext = String(data: decryptedData, encoding: .utf8) else {
                throw CryptoError.decryptionFailed
            }

            guard plaintext.hasPrefix(prefix) else {
                throw CryptoError.invalidPlaintext
            }

            let rawID = String(plaintext.dropFirst(prefix.count))

            #if DEBUG
            MeetingLogger.debug("Decrypted meeting ID: \(rawID)", category: MeetingLogger.crypto)
            #endif

            return rawID
        } catch {
            MeetingLogger.error("Decryption failed: \(error.localizedDescription)", category: MeetingLogger.crypto)
            throw CryptoError.decryptionFailed
        }
    }

    private static func getOrCreateKey() throws -> SymmetricKey {
        if let key = try loadKey() {
            return key
        }

        let newKey = SymmetricKey(size: .bits256)
        try storeKey(newKey)
        return newKey
    }

    private static func loadKey() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            if let data = dataTypeRef as? Data {
                return SymmetricKey(data: data)
            }
        } else if status == errSecItemNotFound {
            return nil
        }

        throw CryptoError.keyNotFound
    }

    private static func storeKey(_ key: SymmetricKey) throws {
        let data = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw CryptoError.storageFailed
        }
    }
}

// MARK: - Data Extensions

extension Data {
    /// Returns a Base64URL-encoded string without padding.
    func base64URLEncodedString() -> String {
        var base64 = self.base64EncodedString()
        base64 = base64.replacingOccurrences(of: "+", with: "-")
        base64 = base64.replacingOccurrences(of: "/", with: "_")
        base64 = base64.replacingOccurrences(of: "=", with: "")
        return base64
    }

    /// Initializes data from a Base64URL-encoded string.
    init?(base64URLSafeString: String) {
        var base64 = base64URLSafeString
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")

        let padding = base64.count % 4
        if padding > 0 {
            base64 += String(repeating: "=", count: 4 - padding)
        }

        self.init(base64Encoded: base64)
    }
}
