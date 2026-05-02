import Foundation
import CryptoKit

class EncryptionService {
    static let shared = EncryptionService()

    private let saltKey = "com.toolskit.security.salt"
    private let iterations = 100_000

    private init() {}

    // Derived key based on master password
    func deriveKey(password: String, salt: Data) throws -> SymmetricKey {
        let passwordData = password.data(using: .utf8)!
        let output = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passwordData),
            salt: salt,
            outputByteCount: 32
        )
        return output
    }

    func generateSalt() -> Data {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }

    func decrypt(_ combinedData: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
        return try AES.GCM.open(sealedBox, using: key)
    }

    // Convenience for strings
    func encryptString(_ text: String, using key: SymmetricKey) throws -> String {
        guard let data = text.data(using: .utf8) else { throw SecurityError.encodingFailed }
        let encrypted = try encrypt(data, using: key)
        return encrypted.base64EncodedString()
    }

    func decryptString(_ base64Text: String, using key: SymmetricKey) throws -> String {
        guard let data = Data(base64Encoded: base64Text) else { throw SecurityError.invalidBase64 }
        let decrypted = try decrypt(data, using: key)
        guard let text = String(data: decrypted, encoding: .utf8) else { throw SecurityError.decodingFailed }
        return text
    }

    // MARK: - Secure Enclave & Key Wrapping

    func generateRandomKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }

    func wrapKey(_ keyToWrap: SymmetricKey, using wrappingKey: SymmetricKey) throws -> Data {
        let keyData = keyToWrap.withUnsafeBytes { Data($0) }
        return try encrypt(keyData, using: wrappingKey)
    }

    func unwrapKey(_ wrappedKeyData: Data, using wrappingKey: SymmetricKey) throws -> SymmetricKey {
        let decryptedData = try decrypt(wrappedKeyData, using: wrappingKey)
        return SymmetricKey(data: decryptedData)
    }

    func encryptWithSecureEnclave(_ data: Data, publicKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let encrypted = SecKeyCreateEncryptedData(publicKey, .eciesEncryptionStandardX963SHA256AESGCM, data as CFData, &error) else {
            throw SecurityError.encryptionFailed
        }
        return encrypted as Data
    }

    func decryptWithSecureEnclave(_ data: Data, privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let decrypted = SecKeyCreateDecryptedData(privateKey, .eciesEncryptionStandardX963SHA256AESGCM, data as CFData, &error) else {
            throw SecurityError.hardwareAuthFailed
        }
        return decrypted as Data
    }
}

enum SecurityError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case invalidBase64
    case encryptionFailed
    case decryptionFailed
    case authenticationFailed
    case keyDerivationFailed
    case itemNotFound
    case secureEnclaveNotAvailable
    case hardwareAuthFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "Failed to encode data."
        case .decodingFailed: return "Failed to decode data."
        case .invalidBase64: return "Invalid Base64 input."
        case .encryptionFailed: return "Encryption failed."
        case .decryptionFailed: return "Decryption failed. Check your master password."
        case .authenticationFailed: return "Authentication failed."
        case .keyDerivationFailed: return "Failed to derive security key."
        case .itemNotFound: return "Item not found in vault."
        case .secureEnclaveNotAvailable: return "Secure Enclave is not available on this device."
        case .hardwareAuthFailed: return "Hardware authentication failed."
        }
    }
}
