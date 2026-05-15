import Foundation
import CryptoKit
import Security

public enum KeyTier: String, Codable, CaseIterable {
    case dev = "DEV"
    case stg = "STG"
    case prd = "PRD"

    public var expiryInterval: TimeInterval? {
        switch self {
        case .dev:
            return 30 * 24 * 60 * 60
        case .stg:
            return 90 * 24 * 60 * 60
        case .prd:
            return nil
        }
    }
}

public struct KeyMetadata: Codable {
    public let tier: KeyTier
    public let generatedAt: Date
    public let entropyBytes: Data
    public let rawKey: String

    public var expiryDate: Date? {
        guard let interval = tier.expiryInterval else { return nil }
        return generatedAt.addingTimeInterval(interval)
    }

    public init(tier: KeyTier, generatedAt: Date, entropyBytes: Data, rawKey: String) {
        self.tier = tier
        self.generatedAt = generatedAt
        self.entropyBytes = entropyBytes
        self.rawKey = rawKey
    }
}

public enum KeyValidationError: Error, LocalizedError {
    case malformedPrefix
    case unknownTier
    case invalidTimestamp
    case entropyLengthMismatch
    case checksumMismatch
    case expired(since: Date)

    public var errorDescription: String? {
        switch self {
        case .malformedPrefix:
            return "Developer ID has an invalid prefix."
        case .unknownTier:
            return "Developer ID has an unknown tier."
        case .invalidTimestamp:
            return "Developer ID has an invalid timestamp."
        case .entropyLengthMismatch:
            return "Developer ID entropy segment is invalid."
        case .checksumMismatch:
            return "Developer ID checksum mismatch."
        case .expired(let since):
            return "Developer ID expired on \(since.formatted(date: .abbreviated, time: .omitted))."
        }
    }
}

public final class DeveloperIDManager {
    public static let shared = DeveloperIDManager()

    private let service = "com.toolskit.developerid"
    private let account = "primary"

    private init() {}

    public static func currentBuildTier() -> KeyTier {
        if let envTier = ProcessInfo.processInfo.environment["TOOLSKIT_TIER"]?.uppercased(), let tier = KeyTier(rawValue: envTier) {
            return tier
        }

        #if DEBUG
        return .dev
        #elseif STAGING
        return .stg
        #else
        return .prd
        #endif
    }

    public func generateKey(tier: KeyTier) throws -> String {
        let timestampMillis = Int64(Date().timeIntervalSince1970 * 1000)
        let timestampB36 = String(timestampMillis, radix: 36).uppercased()

        let entropy = try secureRandomBytes(count: 16)
        let entropyHex = entropy.map { String(format: "%02X", $0) }.joined()

        let checksumInput = "\(tier.rawValue)\(timestampB36)\(entropyHex)"
        let checksum = String(sha256Hex(checksumInput).prefix(6)).uppercased()

        let key = "TK-\(tier.rawValue)-\(timestampB36)-\(entropyHex)-\(checksum)"
        try storeKeyInKeychain(key)
        return key
    }

    public func validate(_ key: String) throws -> KeyMetadata {
        let parts = key.split(separator: "-", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 5, parts[0] == "TK" else {
            throw KeyValidationError.malformedPrefix
        }

        guard let tier = KeyTier(rawValue: parts[1]) else {
            throw KeyValidationError.unknownTier
        }

        guard let timestampMillis = Int64(parts[2], radix: 36), timestampMillis > 0 else {
            throw KeyValidationError.invalidTimestamp
        }

        let entropyHex = parts[3]
        guard entropyHex.count == 32, let entropyData = Data(hexString: entropyHex), entropyData.count == 16 else {
            throw KeyValidationError.entropyLengthMismatch
        }

        let expectedChecksum = String(sha256Hex("\(tier.rawValue)\(parts[2])\(entropyHex)").prefix(6)).uppercased()
        guard parts[4].uppercased() == expectedChecksum else {
            throw KeyValidationError.checksumMismatch
        }

        let generatedAt = Date(timeIntervalSince1970: TimeInterval(timestampMillis) / 1000.0)
        if let expiryDate = tier.expiryInterval.map({ generatedAt.addingTimeInterval($0) }), Date() > expiryDate {
            throw KeyValidationError.expired(since: expiryDate)
        }

        return KeyMetadata(
            tier: tier,
            generatedAt: generatedAt,
            entropyBytes: entropyData,
            rawKey: key
        )
    }

    public func retrieveStoredKey() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data else { return nil }
            return String(data: data, encoding: .utf8)
        case errSecItemNotFound:
            return nil
        default:
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }

    public func deleteStoredKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }

    private func storeKeyInKeychain(_ key: String) throws {
        try deleteStoredKey()

        let data = Data(key.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }

    private func secureRandomBytes(count: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
        return Data(bytes)
    }

    private func sha256Hex(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02X", $0) }.joined()
    }
}

private extension Data {
    init?(hexString: String) {
        guard hexString.count.isMultiple(of: 2) else { return nil }
        var data = Data(capacity: hexString.count / 2)
        var index = hexString.startIndex

        while index < hexString.endIndex {
            let next = hexString.index(index, offsetBy: 2)
            let byteString = hexString[index..<next]
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
            index = next
        }

        self = data
    }
}
