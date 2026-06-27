import Foundation
import Security
import CryptoKit

public actor MTTokenService {
    public static let shared = MTTokenService()
    private init() {}

    public func generate64CharToken() -> String {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data($0).map { String(format: "%02X", $0) }.joined() }
    }

    public func saveToken(_ token: MTTrustToken) throws {
        let data = try JSONEncoder().encode(token)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: MTConstants.keychainService,
            kSecAttrAccount as String: token.gatewayId,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw OpenClawError.keychainError(status) }
    }

    public func getToken(for gatewayId: String) throws -> MTTrustToken? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: MTConstants.keychainService,
            kSecAttrAccount as String: gatewayId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            let token = try JSONDecoder().decode(MTTrustToken.self, from: data)
            if token.expiresAt > Date() {
                return token
            } else {
                deleteToken(for: gatewayId)
            }
        }
        return nil
    }

    public func deleteToken(for gatewayId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: MTConstants.keychainService,
            kSecAttrAccount as String: gatewayId
        ]
        SecItemDelete(query as CFDictionary)
    }
}
