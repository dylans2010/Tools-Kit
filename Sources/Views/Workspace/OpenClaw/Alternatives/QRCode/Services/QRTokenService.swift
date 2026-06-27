import Foundation
import Security

public actor QRTokenService {
    public static let shared = QRTokenService()
    private init() {}

    public func saveToken(_ token: QRTrustToken) throws {
        let data = try JSONEncoder().encode(token)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: QRConstants.keychainService,
            kSecAttrAccount as String: token.gatewayId,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw QRError.keychainError(status) }
    }

    public func getToken(for gatewayId: String) throws -> QRTrustToken? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: QRConstants.keychainService,
            kSecAttrAccount as String: gatewayId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return try JSONDecoder().decode(QRTrustToken.self, from: data)
        }
        return nil
    }

    public func deleteToken(for gatewayId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: QRConstants.keychainService,
            kSecAttrAccount as String: gatewayId
        ]
        SecItemDelete(query as CFDictionary)
    }
}
