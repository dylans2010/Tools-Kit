import Foundation

/// Manages OAuth2 flows, token refresh, and secure credential storage for connectors.
public final class SDKAuthManager {
    public static let shared = SDKAuthManager()

    private init() {}

    public func initiateOAuthFlow(for connectorID: UUID, provider: String) async throws -> URL {
        // In a production app, this would return the auth URL and start a listener for the callback
        return URL(string: "https://auth.toolskit.com/oauth/\(provider)?client_id=tk_sdk")!
    }

    public func saveToken(_ token: String, for connectorID: UUID, key: String) {
        ConnectorAuthManager.shared.saveSecureValue(token, key: key, connectorID: connectorID)
    }

    public func getToken(for connectorID: UUID, key: String) -> String? {
        return ConnectorAuthManager.shared.getSecureValue(key: key, connectorID: connectorID)
    }
}

/// Production-grade secure store interface for connector credentials using Security framework (Keychain).
final class ConnectorAuthManager {
    static let shared = ConnectorAuthManager()
    private let service = "com.toolskit.sdk.connectors"

    private init() {}

    func saveSecureValue(_ value: String, key: String, connectorID: UUID) {
        let fullKey = "\(connectorID.uuidString).\(key)"
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: fullKey,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func getSecureValue(key: String, connectorID: UUID) -> String? {
        let fullKey = "\(connectorID.uuidString).\(key)"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: fullKey,
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
}
