import Foundation
import Security
import OSLog

final class OpenClawSecureStore {
    static let shared = OpenClawSecureStore()
    private let service = "com.toolskit.openclaw"
    private let logger = Logger(subsystem: "com.toolskit.openclaw", category: "Security")

    func saveToken(_ token: String, for deviceId: String) throws {
        guard let data = token.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceId,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            logger.error("Failed to save token for \(deviceId): \(status)")
            throw OpenClawSecurityError.keychainFailure(status)
        }
    }

    func getToken(for deviceId: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func deleteToken(for deviceId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceId
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum OpenClawSecurityError: Error {
    case keychainFailure(OSStatus)
}
