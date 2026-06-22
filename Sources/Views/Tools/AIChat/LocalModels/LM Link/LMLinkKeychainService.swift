import Foundation
import CryptoKit

class LMLinkKeychainService {
    static let shared = LMLinkKeychainService()

    private let service = "com.toolskit.lmlink"
    private let privateKeyAccount = "lmlink.privateKey"
    private let keyIdAccount = "lmlink.keyId"
    private let usernameAccount = "lmlink.username"

    func savePrivateKey(_ key: Curve25519.Signing.PrivateKey) throws {
        let data = key.rawRepresentation
        try saveToKeychain(data: data, account: privateKeyAccount)
    }

    func getPrivateKey() throws -> Curve25519.Signing.PrivateKey? {
        guard let data = try fetchFromKeychain(account: privateKeyAccount) else {
            return nil
        }
        return try Curve25519.Signing.PrivateKey(rawRepresentation: data)
    }

    func saveKeyId(_ keyId: String) throws {
        guard let data = keyId.data(using: .utf8) else { return }
        try saveToKeychain(data: data, account: keyIdAccount)
    }

    func getKeyId() -> String? {
        guard let data = try? fetchFromKeychain(account: keyIdAccount) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func saveUsername(_ username: String) throws {
        guard let data = username.data(using: .utf8) else { return }
        try saveToKeychain(data: data, account: usernameAccount)
    }

    func getUsername() -> String? {
        guard let data = try? fetchFromKeychain(account: usernameAccount) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func deleteKeys() {
        deleteFromKeychain(account: privateKeyAccount)
        deleteFromKeychain(account: keyIdAccount)
        deleteFromKeychain(account: usernameAccount)
    }

    private func saveToKeychain(data: Data, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }

    private func fetchFromKeychain(account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        if status != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }

        return result as? Data
    }

    private func deleteFromKeychain(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
