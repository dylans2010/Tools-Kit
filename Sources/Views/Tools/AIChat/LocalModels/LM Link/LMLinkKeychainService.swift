import Foundation
import Security

final class LMLinkKeychainService {
    private let service = "com.toolskit.lmlink"
    private let credentialAccount = "lmlink.credential"
    private let keyIdAccount = "lmlink.keyId"
    private let userIdAccount = "lmlink.userId"

    func save(credential: String, keyId: String, userId: String) -> Result<Void, LMLinkAuthError> {
        let items = [
            (credentialAccount, credential),
            (keyIdAccount, keyId),
            (userIdAccount, userId)
        ]

        for (account, value) in items {
            guard let data = value.data(using: .utf8) else { continue }
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
                LMLinkLogger.keychain.error("Keychain save failed for \(account): \(status)")
                return .failure(.keychainFailure("OSStatus \(status)"))
            }
        }

        return .success(())
    }

    func load() -> Result<(credential: String, keyId: String, userId: String), LMLinkAuthError> {
        func fetch(account: String) -> String? {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            guard status == errSecSuccess, let data = result as? Data else { return nil }
            return String(data: data, encoding: .utf8)
        }

        guard let credential = fetch(account: credentialAccount),
              let keyId = fetch(account: keyIdAccount),
              let userId = fetch(account: userIdAccount) else {
            return .failure(.keychainFailure("Incomplete session data"))
        }

        return .success((credential, keyId, userId))
    }

    func clear() -> Result<Void, LMLinkAuthError> {
        let accounts = [credentialAccount, keyIdAccount, userIdAccount]
        for account in accounts {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            SecItemDelete(query as CFDictionary)
        }
        return .success(())
    }
}
