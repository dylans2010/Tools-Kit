import Foundation
import CryptoKit
import CommonCrypto

/// Provides encryption, decryption, and key derivation services using CryptoKit and CommonCrypto.
public final class EncryptionService {
    public static let shared = EncryptionService()

    private init() {}

    /// Derives a symmetric key from a password and salt using PBKDF2.
    public func deriveKey(password: String, salt: Data, rounds: Int = 100000) throws -> SymmetricKey {
        guard let passwordData = password.data(using: .utf8) else {
            throw SecurityError.invalidPassword
        }

        var derivedKeyData = Data(count: 32) // AES-256
        let status = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                passwordData.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passwordData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(rounds),
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        derivedKeyData.count
                    )
                }
            }
        }

        guard status == kCCSuccess else {
            throw SecurityError.keyDerivationFailed
        }

        return SymmetricKey(data: derivedKeyData)
    }

    /// Encrypts data using AES-GCM.
    public func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw SecurityError.encryptionFailed
        }
        return combined
    }

    /// Decrypts data using AES-GCM.
    public func decrypt(_ combinedData: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
        return try AES.GCM.open(sealedBox, using: key)
    }

    /// Generates a random salt of specified length.
    public func generateSalt(length: Int = 16) -> Data {
        var data = Data(count: length)
        let result = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!)
        }
        if result == errSecSuccess {
            return data
        } else {
            // Fallback for safety, though SecRandomCopyBytes should not fail
            return Data((0..<length).map { _ in UInt8.random(in: 0...255) })
        }
    }

    /// Computes SHA-256 hash of data.
    public func computeHash(for data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

public enum SecurityError: Error, LocalizedError {
    case invalidPassword
    case keyDerivationFailed
    case encryptionFailed
    case decryptionFailed
    case authenticationFailed
    case vaultLocked
    case itemNotFound

    public var errorDescription: String? {
        switch self {
        case .invalidPassword: return "Invalid password format."
        case .keyDerivationFailed: return "Failed to derive encryption key."
        case .encryptionFailed: return "Encryption operation failed."
        case .decryptionFailed: return "Decryption failed. Incorrect password or corrupted data."
        case .authenticationFailed: return "Authentication challenge failed."
        case .vaultLocked: return "The vault is currently locked."
        case .itemNotFound: return "Requested item not found in vault."
        }
    }
}
