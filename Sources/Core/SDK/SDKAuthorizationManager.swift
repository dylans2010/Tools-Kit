import Foundation
import Combine

public enum AuthState: String, Codable, CaseIterable {
    case unauthenticated
    case authenticating
    case authenticated
    case sessionExpired
    case revoked
}

public struct AuthSession: Codable, Hashable {
    public let sessionId: String
    public let developerId: String?
    public let issuedAt: Date
    public let expiresAt: Date
    public let refreshToken: String?
    public let scopes: [String]

    public init(
        sessionId: String,
        developerId: String?,
        issuedAt: Date,
        expiresAt: Date,
        refreshToken: String? = nil,
        scopes: [String]
    ) {
        self.sessionId = sessionId
        self.developerId = developerId
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
        self.scopes = scopes
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
        developerId: String? = nil,
        scopes: [String],
        sessionDuration: TimeInterval = 60 * 60,
        refreshToken: String? = nil
    ) -> AuthSession {
        authState = .authenticating

        let now = Date()
        let session = AuthSession(
            sessionId: UUID().uuidString,
            developerId: developerId,
            issuedAt: now,
            expiresAt: now.addingTimeInterval(max(1, sessionDuration)),
            refreshToken: refreshToken,
            scopes: normalizeScopes(scopes)
        )

        authSession = session
        authState = .authenticated
        persistSession(session)
        reevaluateAccessControls()
        return session
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
            developerId: session.developerId,
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

    private func ensureActiveSession() -> Bool {
        switch authState {
        case .authenticated:
            if let session = authSession, session.isExpired {
                authState = .sessionExpired
                clearPersistedSession()
                reevaluateAccessControls()
                return false
            }
            return authSession != nil
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
