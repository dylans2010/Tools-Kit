import Foundation
import Security

class APIKeyManager {
    nonisolated(unsafe) static let shared = APIKeyManager()
    private let service = "com.tools-kit.keys"

    // MARK: - Per-provider key storage

    func saveKey(_ key: String, for providerID: String) -> Bool {
        guard let data = key.data(using: .utf8) else { return false }
        let account = accountName(for: providerID)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    func getKey(for providerID: String) -> String? {
        let account = accountName(for: providerID)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
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

    func deleteKey(for providerID: String) {
        let account = accountName(for: providerID)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    func hasKey(for providerID: String) -> Bool {
        getKey(for: providerID) != nil
    }

    // MARK: - Legacy single-key support (OpenRouter backward compat)

    func saveKey(_ key: String) -> Bool {
        saveKey(key, for: "openrouter")
    }

    func getKey() -> String? {
        getKey(for: "openrouter")
    }

    func deleteKey() {
        deleteKey(for: "openrouter")
    }

    // MARK: - Unsplash Credentials

    var unsplashAccessKey: String? {
        get { getKey(for: "unsplash") }
        set {
            if let value = newValue, !value.isEmpty {
                _ = saveKey(value, for: "unsplash")
            } else {
                deleteKey(for: "unsplash")
            }
        }
    }

    var unsplashSecretKey: String? {
        get { getKey(for: "unsplash-secret") }
        set {
            if let value = newValue, !value.isEmpty {
                _ = saveKey(value, for: "unsplash-secret")
            } else {
                deleteKey(for: "unsplash-secret")
            }
        }
    }

    var unsplashApplicationID: String? {
        get { getKey(for: "unsplash-app-id") }
        set {
            if let value = newValue, !value.isEmpty {
                _ = saveKey(value, for: "unsplash-app-id")
            } else {
                deleteKey(for: "unsplash-app-id")
            }
        }
    }

    var hasUnsplashCredentials: Bool {
        guard let key = unsplashAccessKey else { return false }
        return !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Private

    private func accountName(for providerID: String) -> String {
        "\(providerID)-api-key"
    }
}
