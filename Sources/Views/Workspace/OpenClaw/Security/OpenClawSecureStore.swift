import Foundation
import Security

final class OpenClawSecureStore {
    static let shared = OpenClawSecureStore()
    private let service = "com.toolskit.openclaw"

    private init() {}

    func saveToken(_ token: String, for deviceID: String) {
        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Keychain: Saving token for \(deviceID)", type: .info)
        }
        let data = Data(token.utf8)

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceID
        ]

        let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
        if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Keychain: Failed to delete existing item: \(deleteStatus)", type: .error)
            }
        }

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceID,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus == errSecSuccess {
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Token stored successfully for \(deviceID)", type: .info)
            }
        } else {
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Keychain: Failed to add item: \(addStatus)", type: .error)
            }
        }
    }

    func getToken(for deviceID: String) -> String? {
        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Starting token lookup for \(deviceID)", type: .info)
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceID,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Keychain query: service=\(service), account=\(deviceID)", type: .info)
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            let token = String(data: data, encoding: .utf8)
            let length = token?.count ?? 0
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Token found (length: \(length))", type: .info)
            }
            return token
        } else {
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Token missing (status: \(status))", type: .info)
            }
        }
        return nil
    }

    func deleteToken(for deviceID: String) {
        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Keychain: Deleting token for \(deviceID)", type: .info)
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceID
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Keychain: Failed to delete item: \(status)", type: .error)
            }
        }
    }
}
