import Foundation
import Security

public final class SDKStorageManager {
    public static let shared = SDKStorageManager()

    private let localStorageURL: URL
    private var localStorage: [String: String] = [:]
    private let queue = DispatchQueue(label: "com.toolskit.sdk.storage", qos: .utility)
    private static let keychainService = "com.toolskit.sdk.securestorage"

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        localStorageURL = appSupport.appendingPathComponent("sdk_local_storage.json")

        if !FileManager.default.fileExists(atPath: appSupport.path) {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        loadLocalStorage()
    }

    // MARK: - Local Storage

    public func getValue(key: String) -> Any? {
        return localStorage[key]
    }

    public func setValue(key: String, value: Any) {
        localStorage[key] = String(describing: value)
        persistLocalStorage()
    }

    public func removeValue(key: String) {
        localStorage.removeValue(forKey: key)
        persistLocalStorage()
    }

    public func allKeys() -> [String] {
        return Array(localStorage.keys)
    }

    public func clearLocalStorage() {
        localStorage.removeAll()
        persistLocalStorage()
    }

    // MARK: - Secure Storage (Keychain)

    public func getSecureValue(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: SDKStorageManager.keychainService,
            kSecAttrAccount as String: key,
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

    public func setSecureValue(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw SDKError.executionFailed(reason: "Failed to encode value")
        }

        let existingQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: SDKStorageManager.keychainService,
            kSecAttrAccount as String: key
        ]

        let existing = SecItemCopyMatching(existingQuery as CFDictionary, nil)

        if existing == errSecSuccess {
            let updateAttrs: [String: Any] = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(existingQuery as CFDictionary, updateAttrs as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw SDKError.executionFailed(reason: "Keychain update failed: \(updateStatus)")
            }
        } else {
            var addQuery = existingQuery
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw SDKError.executionFailed(reason: "Keychain add failed: \(addStatus)")
            }
        }

        SDKLogStore.shared.log("Secure value stored for key: \(key)", source: "SDKStorageManager", level: .info)
    }

    public func deleteSecureValue(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: SDKStorageManager.keychainService,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Private

    private func persistLocalStorage() {
        let storageSnapshot = localStorage
        queue.async { [weak self] in
            guard let url = self?.localStorageURL else { return }
            if let data = try? JSONEncoder().encode(storageSnapshot) {
                try? data.write(to: url)
            }
        }
    }

    private func loadLocalStorage() {
        guard let data = try? Data(contentsOf: localStorageURL),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else { return }
        localStorage = decoded
    }
}
