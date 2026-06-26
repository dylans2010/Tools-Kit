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

        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Keychain save query for \(deviceID)", type: .info)
        }

        let deleteStatus = SecItemDelete(query as CFDictionary)
        let addStatus = SecItemAdd(query as CFDictionary, nil)

        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Keychain save status: \(addStatus) (delete: \(deleteStatus))", type: .info)
        }
    }

    func getToken(for deviceID: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceID,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Keychain query for \(deviceID)", type: .info)
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Token found. Length: \(data.count)", type: .info)
            }
            return String(data: data, encoding: .utf8)
        }
        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Token missing. Status: \(status)", type: .info)
        }
        return nil
    }

    func deleteToken(for deviceID: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceID
        ]
        let status = SecItemDelete(query as CFDictionary)
        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Keychain delete status for \(deviceID): \(status)", type: .info)
        }
    }
}
