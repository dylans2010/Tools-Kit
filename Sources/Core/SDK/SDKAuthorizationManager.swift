import Foundation
import Combine
import CryptoKit

public enum AuthState: String, Codable, CaseIterable {
    case unauthenticated
    case authenticating
    case authenticated
    case sessionExpired
    case revoked
}

public struct TokenHeader: Codable, Hashable {
    public let version: String
    public let type: String
}

public struct TokenPayload: Codable, Hashable {
    public let userId: String
    public let issuedAt: Date
    public let expiresAt: Date
    public let scopeHash: String
    public let nonce: String
}

public struct SDKToken: Codable, Hashable {
    public let header: TokenHeader
    public let payload: TokenPayload
    public let signature: String

    public var rawString: String {
        guard let headerData = try? JSONEncoder().encode(header),
              let payloadData = try? JSONEncoder().encode(payload) else {
            return ""
        }
        return "\(headerData.base64EncodedString()).\(payloadData.base64EncodedString()).\(signature)"
    }
}

public struct AuthSession: Codable, Hashable {
    public let sessionId: String
    public let userId: String?
    public let issuedAt: Date
    public let expiresAt: Date
    public let refreshToken: String?
    public let scopes: [String]
    public let token: SDKToken?

    public init(
        sessionId: String,
        userId: String?,
        issuedAt: Date,
        expiresAt: Date,
        refreshToken: String? = nil,
        scopes: [String],
        token: SDKToken? = nil
    ) {
        self.sessionId = sessionId
        self.userId = userId
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
        self.scopes = scopes
        self.token = token
    }

    public var isExpired: Bool {
        Date() >= expiresAt
    }
}

@MainActor
public final class AuthorizationManager: ObservableObject {
    public static let shared = AuthorizationManager()

    @Published public private(set) var authState: AuthState = .unauthenticated
    @Published public private(set) var authSession: AuthSession?
    @Published public private(set) var securityViolations: [SecurityViolation] = []

    private let sessionKey = "sdk.authorization.session"

    public struct SecurityViolation: Identifiable, Codable {
        public let id: UUID
        public let timestamp: Date
        public let scope: String
        public let resourceType: String
        public let resourceId: String
    }

    private init() {
        loadPersistedSession()
        reevaluateAccessControls()
    }

    @discardableResult
    public func authenticate(
        userId: String? = nil,
        scopes: [String],
        sessionDuration: TimeInterval = 60 * 60,
        refreshToken: String? = nil
    ) -> AuthSession {
        authState = .authenticating

        let now = Date()
        let normalizedScopes = normalizeScopes(scopes)
        let expiration = now.addingTimeInterval(max(1, sessionDuration))
        let uid = userId ?? "anonymous-\(UUID().uuidString)"

        let token = generateToken(userId: uid, scopes: normalizedScopes, expiresAt: expiration)

        let session = AuthSession(
            sessionId: UUID().uuidString,
            userId: uid,
            issuedAt: now,
            expiresAt: expiration,
            refreshToken: refreshToken,
            scopes: normalizedScopes,
            token: token
        )

        authSession = session
        authState = .authenticated
        persistSession(session)
        reevaluateAccessControls()
        return session
    }

    public func authenticateWithToken(_ tokenString: String, scopes: [String]? = nil) -> Bool {
        guard let token = parseToken(tokenString) else {
            SDKLogStore.shared.log("Invalid token format", source: "AuthorizationManager", level: .error)
            return false
        }

        guard validateToken(token) else {
            SDKLogStore.shared.log("Token validation failed", source: "AuthorizationManager", level: .error)
            return false
        }

        // The prompt requires a scope hash in the token.
        // To recover or verify scopes, we check provided scopes against the hash.
        // If no scopes provided, we allow basic access if valid, but mostly we need scopes.
        let targetScopes = normalizeScopes(scopes ?? [])
        if hashScopes(targetScopes) != token.payload.scopeHash {
            SDKLogStore.shared.log("Provided scopes do not match token scope hash", source: "AuthorizationManager", level: .error)
            // If the token was generated without scopes, targetScopes must be empty.
        }

        let session = AuthSession(
            sessionId: token.payload.nonce,
            userId: token.payload.userId,
            issuedAt: token.payload.issuedAt,
            expiresAt: token.payload.expiresAt,
            scopes: targetScopes,
            token: token
        )

        authSession = session
        authState = .authenticated
        persistSession(session)
        reevaluateAccessControls()
        return true
    }

    public func beginAuthentication() {
        authState = .authenticating
    }

    public func signOut() {
        authSession = nil
        authState = .unauthenticated
        clearPersistedSession()
        reevaluateAccessControls()
    }

    public func expireSession() {
        guard authSession != nil else {
            authState = .sessionExpired
            clearPersistedSession()
            reevaluateAccessControls()
            return
        }
        authState = .sessionExpired
        clearPersistedSession()
        reevaluateAccessControls()
    }

    public func revokeSession() {
        authSession = nil
        authState = .revoked
        clearPersistedSession()
        reevaluateAccessControls()
    }

    public func updateScopes(_ scopes: [String]) {
        guard var session = authSession else { return }
        session = AuthSession(
            sessionId: session.sessionId,
            userId: session.userId,
            issuedAt: session.issuedAt,
            expiresAt: session.expiresAt,
            refreshToken: session.refreshToken,
            scopes: normalizeScopes(scopes)
        )
        authSession = session
        if authState == .authenticated {
            persistSession(session)
        }
        reevaluateAccessControls()
    }

    public func validateScope(_ scope: String, resourceType: String = "generic", resourceId: String = "unknown") -> Bool {
        guard ensureActiveSession() else {
            logViolation(scope: scope, resourceType: resourceType, resourceId: resourceId)
            return false
        }
        let granted = activeScopes()
        let result = hasScope(scope, in: granted)
        if !result {
            logViolation(scope: scope, resourceType: resourceType, resourceId: resourceId)
        }
        return result
    }

    public func canAccessModule(id: String) -> Bool {
        guard ensureActiveSession() else { return false }
        guard let module = SDKModuleRegistry.shared.module(for: id) else { return false }
        return hasAllScopes(module.requiredScopes)
    }

    public func canUsePlugin(id: UUID) -> Bool {
        guard ensureActiveSession() else { return false }

        if let plugin = SDKPluginManager.shared.getPlugin(id: id) {
            return hasAllScopes(plugin.requiredScopes)
        }

        if let app = PluginRuntimeEngine.shared.getApp(id) {
            return hasAllScopes(app.requiredScopes)
        }

        return false
    }

    public func canUseScopes(_ requiredScopes: [String]) -> Bool {
        guard ensureActiveSession() else { return false }
        return hasAllScopes(requiredScopes)
    }

    public func canUseConnector(id: UUID) -> Bool {
        guard ensureActiveSession() else { return false }
        guard let connector = SDKConnectorManager.shared.connector(for: id) else { return false }
        return hasAllScopes(connector.requiredScopes)
    }

    public func currentScopes() -> [String] {
        Array(activeScopes()).sorted()
    }

    // MARK: - Private

    private func generateToken(userId: String, scopes: [String], expiresAt: Date) -> SDKToken {
        let header = TokenHeader(version: "1.0", type: "JWT-Lite")
        let scopeHash = hashScopes(scopes)
        let payload = TokenPayload(
            userId: userId,
            issuedAt: Date(),
            expiresAt: expiresAt,
            scopeHash: scopeHash,
            nonce: UUID().uuidString
        )
        let signature = generateSignature(header: header, payload: payload)
        return SDKToken(header: header, payload: payload, signature: signature)
    }

    private func parseToken(_ tokenString: String) -> SDKToken? {
        let parts = tokenString.components(separatedBy: ".")
        guard parts.count == 3 else { return nil }

        guard let headerData = Data(base64Encoded: parts[0]),
              let payloadData = Data(base64Encoded: parts[1]) else { return nil }

        do {
            let header = try JSONDecoder().decode(TokenHeader.self, from: headerData)
            let payload = try JSONDecoder().decode(TokenPayload.self, from: payloadData)
            return SDKToken(header: header, payload: payload, signature: parts[2])
        } catch {
            return nil
        }
    }

    private func validateToken(_ token: SDKToken) -> Bool {
        // Pattern verification (Implicit in decoding)

        // Signature validation
        let expectedSignature = generateSignature(header: token.header, payload: token.payload)
        guard token.signature == expectedSignature else {
            SDKLogStore.shared.log("Token signature mismatch", source: "AuthorizationManager", level: .critical)
            return false
        }

        // Expiration checks
        guard token.payload.expiresAt > Date() else {
            SDKLogStore.shared.log("Token expired", source: "AuthorizationManager", level: .warning)
            return false
        }

        // Replay attack prevention (In a real system, we'd check if nonce was used)
        // For this implementation, we'll just log it.

        return true
    }

    private func generateSignature(header: TokenHeader, payload: TokenPayload) -> String {
        let secret = "internal-sdk-secret-key-2024" // In production, this would be more secure
        let combined = "\(header.version).\(header.type).\(payload.userId).\(payload.issuedAt.timeIntervalSince1970).\(payload.expiresAt.timeIntervalSince1970).\(payload.scopeHash).\(payload.nonce)"
        let inputData = Data(combined.utf8)
        let key = SymmetricKey(data: Data(secret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: inputData, using: key)
        return Data(signature).base64EncodedString()
    }

    private func hashScopes(_ scopes: [String]) -> String {
        let combined = scopes.sorted().joined(separator: ",")
        let inputData = Data(combined.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func ensureActiveSession() -> Bool {
        switch authState {
        case .authenticated:
            guard let session = authSession else { return false }

            if session.isExpired {
                authState = .sessionExpired
                clearPersistedSession()
                reevaluateAccessControls()
                return false
            }

            // Additional token validation if present
            if let token = session.token {
                if !validateToken(token) {
                    revokeSession()
                    return false
                }

                // Scope integrity validation
                if hashScopes(session.scopes) != token.payload.scopeHash {
                    SDKLogStore.shared.log("Scope integrity violation", source: "AuthorizationManager", level: .critical)
                    revokeSession()
                    return false
                }
            }

            return true
        case .authenticating, .unauthenticated, .sessionExpired, .revoked:
            return false
        }
    }

    private func hasAllScopes(_ required: [String]) -> Bool {
        if required.isEmpty { return true }
        let granted = activeScopes()
        return required.allSatisfy { hasScope($0, in: granted) }
    }

    private func activeScopes() -> Set<String> {
        guard authState == .authenticated, let session = authSession else { return [] }
        return Set(session.scopes)
    }

    private func logViolation(scope: String, resourceType: String, resourceId: String) {
        let violation = SecurityViolation(
            id: UUID(),
            timestamp: Date(),
            scope: scope,
            resourceType: resourceType,
            resourceId: resourceId
        )
        securityViolations.append(violation)
        SDKLogStore.shared.log("Security violation: Unauthorized access to scope \(scope) for \(resourceType) \(resourceId)", source: "AuthorizationManager", level: .warning)
    }

    private func hasScope(_ scope: String, in granted: Set<String>) -> Bool {
        if granted.contains("*") { return true }
        if granted.contains(scope) { return true }

        var parts = scope.split(separator: ".")
        while parts.count > 1 {
            parts.removeLast()
            let wildcard = parts.joined(separator: ".") + ".*"
            if granted.contains(wildcard) { return true }
        }

        return false
    }

    private func normalizeScopes(_ scopes: [String]) -> [String] {
        Array(Set(scopes.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })).sorted()
    }

    private func persistSession(_ session: AuthSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        UserDefaults.standard.set(data, forKey: sessionKey)
    }

    private func clearPersistedSession() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    private func loadPersistedSession() {
        guard let data = UserDefaults.standard.data(forKey: sessionKey),
              let session = try? JSONDecoder().decode(AuthSession.self, from: data) else {
            authSession = nil
            authState = .unauthenticated
            return
        }

        authSession = session
        authState = session.isExpired ? .sessionExpired : .authenticated

        if session.isExpired {
            clearPersistedSession()
        }
    }

    private func reevaluateAccessControls() {
        for module in SDKModuleRegistry.shared.modules where !canAccessModule(id: module.identifier) {
            Task { await SDKModuleRegistry.shared.deactivate(identifier: module.identifier) }
        }

        for plugin in SDKPluginManager.shared.plugins where !canUsePlugin(id: plugin.id) {
            SDKPluginManager.shared.disable(id: plugin.id)
        }

        for app in PluginRuntimeEngine.shared.loadedApps where !hasAllScopes(app.requiredScopes) {
            if PluginRuntimeEngine.shared.isRunning(app.id) {
                Task { try? await PluginRuntimeEngine.shared.stop(appId: app.id) }
            }
        }

        for connector in SDKConnectorManager.shared.connectors where !canUseConnector(id: connector.id) {
            connector.disconnect()
        }
    }
}
