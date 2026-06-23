import Foundation

struct LMLinkCallbackParser {
    enum CallbackResult {
        case success(credential: String, keyId: String, publicKey: String, userId: String)
        case cancelled
        case denied
        case error(reason: String)
        case malformed
    }

    static func parse(url: URL) -> CallbackResult {
        LMLinkLogger.deeplink.info("Parsing callback URL: \(url.absoluteString, privacy: .private(mask: .hash))")

        guard url.scheme == "toolskit", url.host == "lm-callback" else {
            LMLinkLogger.deeplink.error("Malformed callback: Invalid scheme (\(url.scheme ?? "nil", privacy: .public)) or host (\(url.host ?? "nil", privacy: .public))")
            return .malformed
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            LMLinkLogger.deeplink.error("Malformed callback: Could not extract query parameters")
            return .malformed
        }

        let params = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item -> (String, String)? in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })

        LMLinkLogger.deeplink.info("Callback parameters received: \(params.keys.joined(separator: ", "), privacy: .public)")

        if let error = params["error"] {
            LMLinkLogger.deeplink.info("Callback returned error: \(error, privacy: .public)")
            switch error {
            case "cancelled", "cancel": return .cancelled
            case "denied", "access_denied": return .denied
            default: return .error(reason: error)
            }
        }

        // lmstudio.ai returns the credential under "credential", "token", or "access_token"
        let credential = params["credential"] ?? params["token"] ?? params["access_token"]
        guard let credential, !credential.isEmpty else {
            LMLinkLogger.deeplink.error("Callback missing credential param. Available keys: \(params.keys.joined(separator: ", "), privacy: .public)")
            return .malformed
        }

        let keyId = params["keyId"] ?? params["key_id"] ?? ""
        let publicKey = params["publicKey"] ?? params["public_key"] ?? ""
        let userId = params["userId"] ?? params["user_id"] ?? params["accountId"] ?? ""

        if keyId.isEmpty {
            LMLinkLogger.deeplink.warning("Callback missing keyId")
        }

        if publicKey.isEmpty {
            LMLinkLogger.deeplink.warning("Callback missing publicKey")
        }

        LMLinkLogger.deeplink.info("Callback parsed successfully. keyId: \(keyId, privacy: .private(mask: .hash)), userId: \(userId, privacy: .private(mask: .hash))")
        return .success(credential: credential, keyId: keyId, publicKey: publicKey, userId: userId)
    }
}
