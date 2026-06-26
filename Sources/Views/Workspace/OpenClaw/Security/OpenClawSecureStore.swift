import Foundation
import Security

final class OpenClawSecureStore {
    static let shared = OpenClawSecureStore()
    private let service = "com.toolskit.openclaw"

    private init() {}

    func saveToken(_ token: String, for deviceID: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceID,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        OpenClawLoggerService.shared.log(
            level: .debug,
            category: .authentication,
            title: "Keychain Save",
            description: "Saving token for device \(deviceID)"
        )

        let deleteStatus = SecItemDelete(query as CFDictionary)
        let addStatus = SecItemAdd(query as CFDictionary, nil)

        OpenClawLoggerService.shared.log(
            level: addStatus == errSecSuccess ? .debug : .error,
            category: .authentication,
            title: "Keychain Status",
            description: "Add: \(addStatus), Delete: \(deleteStatus)"
        )
    }

    func getToken(for deviceID: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceID,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        OpenClawLoggerService.shared.log(
            level: .debug,
            category: .authentication,
            title: "Keychain Query",
            description: "Fetching token for device \(deviceID)"
        )

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            OpenClawLoggerService.shared.log(
                level: .debug,
                category: .authentication,
                title: "Token Found",
                description: "Length: \(data.count) bytes"
            )
            return String(data: data, encoding: .utf8)
        }
        OpenClawLoggerService.shared.log(
            level: status == errSecItemNotFound ? .info : .error,
            category: .authentication,
            title: "Token Missing",
            description: "Keychain status: \(status)"
        )
        return nil
    }

    func deleteToken(for deviceID: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceID
        ]
        let status = SecItemDelete(query as CFDictionary)
        OpenClawLoggerService.shared.log(
            level: .info,
            category: .authentication,
            title: "Keychain Delete",
            description: "Device: \(deviceID), Status: \(status)"
        )
    }
}
