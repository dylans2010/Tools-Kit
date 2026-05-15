import Foundation
import CryptoKit
import Security
import os.Logger

public enum KeyTier: String, Codable {
    case dev = "DEV"
    case stg = "STG"
    case prd = "PRD"
}

public struct KeyMetadata {
    public let tier: KeyTier
    public let generatedAt: Date
    public let entropyBytes: Data
    public let rawKey: String

    public var expiryDate: Date? {
        switch tier {
        case .dev:
            return Calendar.current.date(byAdding: .day, value: 30, to: generatedAt)
        case .stg:
            return Calendar.current.date(byAdding: .day, value: 90, to: generatedAt)
        case .prd:
            return nil
        }
    }
}

public enum KeyValidationError: LocalizedError {
    case malformedPrefix
    case unknownTier
    case invalidTimestamp
    case entropyLengthMismatch
    case checksumMismatch
    case expired(since: Date)

    public var errorDescription: String? {
        switch self {
        case .malformedPrefix: return "Malformed product prefix."
        case .unknownTier: return "Unknown environment tier."
        case .invalidTimestamp: return "Invalid timestamp encoding."
        case .entropyLengthMismatch: return "Entropy length mismatch."
        case .checksumMismatch: return "Integrity checksum mismatch."
        case .expired(let date): return "Developer ID expired on \(date.formatted())."
        }
    }
}

final class AuthRootView {
    static let shared = AuthRootView()
    private let logger = Logger(subsystem: "com.toolskit.auth", category: "DeveloperID")

    private let keychainService = "com.toolskit.developerid"
    private let keychainAccount = "primary"

    private init() {}

    // MARK: - Key Generation

    func generateKey(tier: KeyTier) throws -> String {
        let prefix = "TK"
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let timestampB36 = String(timestamp, radix: 36).uppercased()

        var entropy = Data(count: 16)
        let result = entropy.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!)
        }
        guard result == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(result))
        }
        let entropyHex = entropy.map { String(format: "%02X", $0) }.joined()

        let material = "\(tier.rawValue)\(timestampB36)\(entropyHex)"
        let hash = SHA256.hash(data: Data(material.utf8))
        let checksum = hash.map { String(format: "%02X", $0) }.joined().prefix(6)

        let key = "\(prefix)-\(tier.rawValue)-\(timestampB36)-\(entropyHex)-\(checksum)"

        try storeKey(key)
        logger.info("Generated new Developer ID for tier: \(tier.rawValue)")

        return key
    }

    // MARK: - Validation

    func validate(_ key: String) throws -> KeyMetadata {
        let components = key.components(separatedBy: "-")
        guard components.count == 5, components[0] == "TK" else {
            throw KeyValidationError.malformedPrefix
        }

        guard let tier = KeyTier(rawValue: components[1]) else {
            throw KeyValidationError.unknownTier
        }

        let timestampB36 = components[2]
        guard let timestampMs = Int64(timestampB36, radix: 36) else {
            throw KeyValidationError.invalidTimestamp
        }
        let generatedAt = Date(timeIntervalSince1970: TimeInterval(timestampMs) / 1000.0)

        let entropyHex = components[3]
        guard entropyHex.count == 32 else {
            throw KeyValidationError.entropyLengthMismatch
        }

        let checksum = components[4]
        let material = "\(tier.rawValue)\(timestampB36)\(entropyHex)"
        let hash = SHA256.hash(data: Data(material.utf8))
        let expectedChecksum = hash.map { String(format: "%02X", $0) }.joined().prefix(6)

        guard checksum == expectedChecksum else {
            throw KeyValidationError.checksumMismatch
        }

        let metadata = KeyMetadata(
            tier: tier,
            generatedAt: generatedAt,
            entropyBytes: Data(entropyHex.utf8), // Task says 16 bytes of SecRandomCopyBytes output, hex-encoded. We store metadata with entropyBytes.
            rawKey: key
        )

        if let expiryDate = metadata.expiryDate, expiryDate < Date() {
            throw KeyValidationError.expired(since: expiryDate)
        }

        return metadata
    }

    // MARK: - Keychain Storage

    private func storeKey(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: Data(key.utf8)
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }

    func retrieveStoredKey() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }

        throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }

    func deleteStoredKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
}
