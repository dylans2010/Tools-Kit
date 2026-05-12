import Foundation
import Security

class MailKeychainManager {
    nonisolated(unsafe) static let shared = MailKeychainManager()
    private let service = "com.tools-kit.mail"
    private let oauthService = "com.tools-kit.mail.oauth"

    func saveCredentials(email: String, password: String) -> Bool {
        guard let data = password.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: email,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        InternalLogger.shared.log("MailKeychain: saved iCloud credentials for \(email)", level: .info)
        return status == errSecSuccess
    }

    func getPassword(for email: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: email,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    func deleteCredentials(for email: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: email
        ]
        SecItemDelete(query as CFDictionary)
        InternalLogger.shared.log("MailKeychain: deleted iCloud credentials for \(email)", level: .info)
    }

    func saveOAuthTokens(accountId: String, accessToken: String, refreshToken: String?) -> Bool {
        var tokenPayload: [String: String] = ["accessToken": accessToken]
        if let refreshToken, !refreshToken.isEmpty {
            tokenPayload["refreshToken"] = refreshToken
        }

        guard let data = try? JSONEncoder().encode(tokenPayload) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: oauthService,
            kSecAttrAccount as String: accountId,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        InternalLogger.shared.log("MailKeychain: saved OAuth tokens for account \(accountId)", level: .info)
        return status == errSecSuccess
    }

    func getOAuthTokens(accountId: String) -> (accessToken: String, refreshToken: String?)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: oauthService,
            kSecAttrAccount as String: accountId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        guard status == errSecSuccess, let data = dataTypeRef as? Data else { return nil }
        guard let payload = try? JSONDecoder().decode([String: String].self, from: data) else { return nil }
        guard let accessToken = payload["accessToken"], !accessToken.isEmpty else { return nil }
        return (accessToken: accessToken, refreshToken: payload["refreshToken"])
    }

    func deleteOAuthTokens(accountId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: oauthService,
            kSecAttrAccount as String: accountId
        ]
        SecItemDelete(query as CFDictionary)
        InternalLogger.shared.log("MailKeychain: deleted OAuth tokens for account \(accountId)", level: .info)
    }
}
