import Foundation
import Security

/// Manages GitHub authentication and secure token storage.
final class GitHubAuthManager {
    static let shared = GitHubAuthManager()

    private let service = "com.tools-kit.github"
    private let tokenKey = "github_personal_access_token"

    private init() {}

    /// Saves the GitHub Personal Access Token to the Keychain.
    /// - Parameter token: The PAT to save.
    /// - Returns: Boolean indicating success.
    @discardableResult
    func saveToken(_ token: String) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Retrieves the GitHub Personal Access Token from the Keychain.
    /// - Returns: The stored token if available.
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey,
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

    /// Deletes the GitHub token from the Keychain.
    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey
        ]
        SecItemDelete(query as CFDictionary)
    }

    /// Validates the stored token by calling GitHub's user endpoint.
    /// - Returns: Boolean indicating if the token is valid.
    func validateToken() async -> Bool {
        guard let token = getToken() else { return false }

        var request = URLRequest(url: URL(string: "https://api.github.com/user")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Tools-Kit-iOS", forHTTPHeaderField: "User-Agent")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }
}
