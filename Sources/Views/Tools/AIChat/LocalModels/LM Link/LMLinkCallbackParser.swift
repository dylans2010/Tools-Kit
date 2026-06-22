import Foundation

struct LMLinkCallbackParser {
    enum CallbackResult {
        case success(credential: String, keyId: String, userId: String)
        case cancelled
        case denied
        case error(reason: String)
        case malformed
    }

    static func parse(url: URL) -> CallbackResult {
        guard url.scheme == "toolskit", url.host == "lm-callback" else {
            return .malformed
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return .malformed
        }
        let params = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item -> (String, String)? in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })
        if let error = params["error"] {
            switch error {
            case "cancelled", "cancel": return .cancelled
            case "denied", "access_denied": return .denied
            default: return .error(reason: error)
            }
        }
        // lmstudio.ai returns the credential under "credential" or "token"
        let credential = params["credential"] ?? params["token"] ?? params["access_token"]
        guard let credential, !credential.isEmpty else {
            LMLinkLogger.deeplink.error("Callback missing credential param. Keys: \(params.keys.joined(separator: ", "), privacy: .public)")
            return .malformed
        }
        let keyId = params["keyId"] ?? params["key_id"] ?? ""
        let userId = params["userId"] ?? params["user_id"] ?? params["accountId"] ?? ""
        LMLinkLogger.deeplink.info("Callback parsed successfully. keyId: \(keyId, privacy: .private(mask: .hash))")
        return .success(credential: credential, keyId: keyId, userId: userId)
    }
}
