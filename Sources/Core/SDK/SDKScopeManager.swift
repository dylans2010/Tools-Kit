import Foundation
import Combine

@MainActor
public final class SDKScopeManager: ObservableObject {
    public static let shared = SDKScopeManager()

    @Published public var authorizedScopes: Set<String> = []
    @Published public var scopeAuditLog: [ScopeAuditEntry] = []

    private let persistenceKey = "sdk_authorized_scopes"
    private let maxAuditEntries = 500

    public enum Operation: String, Sendable {
        case read, write, delete, execute
    }

    public struct ScopeAuditEntry: Identifiable, Sendable {
        public let id = UUID()
        public let timestamp = Date()
        public let scope: String
        public let operation: Operation
        public let granted: Bool
        public let reason: String?
    }

    private init() {
        loadAuthorizedScopes()
    }

    public func validateAccess(scope: SDKScope, operation: Operation) throws {
        if SDKRuntimeEngine.shared.isNoSandboxModeEnabled {
            recordAudit(scope: scopeString(for: scope, operation: operation), operation: operation, granted: true, reason: "noSandbox mode active")
            return
        }

        let requiredScope = scopeString(for: scope, operation: operation)

        guard isScopeAuthorized(requiredScope) else {
            recordAudit(scope: requiredScope, operation: operation, granted: false, reason: "Scope not authorized")
            throw SDKError.permissionDenied(scope: requiredScope)
        }

        recordAudit(scope: requiredScope, operation: operation, granted: true, reason: nil)
    }

    public func authorizeScope(_ scope: String) {
        authorizedScopes.insert(scope)
        persistScopes()
        SDKLogStore.shared.log("Scope authorized: \(scope)", source: "SDKScopeManager", level: LogLevel.info)
    }

    public func revokeScope(_ scope: String) {
        authorizedScopes.remove(scope)
        persistScopes()
        SDKLogStore.shared.log("Scope revoked: \(scope)", source: "SDKScopeManager", level: LogLevel.info)
    }

    public func authorizeAllScopes() {
        for scope in SDKScope.allCases {
            for op in [Operation.read, .write, .delete, .execute] {
                authorizedScopes.insert(scopeString(for: scope, operation: op))
            }
        }
        persistScopes()
    }

    public func isAuthorized(scope: SDKScope, operation: Operation) -> Bool {
        if SDKRuntimeEngine.shared.isNoSandboxModeEnabled { return true }
        return isScopeAuthorized(scopeString(for: scope, operation: operation))
    }

    // MARK: - Private

    private func isScopeAuthorized(_ scope: String) -> Bool {
        if authorizedScopes.isEmpty {
            return true
        }
        if authorizedScopes.contains("*") { return true }
        if authorizedScopes.contains(scope) { return true }

        let wildcardPrefix = scope.components(separatedBy: ".").dropLast().joined(separator: ".") + ".*"
        return authorizedScopes.contains(wildcardPrefix)
    }

    private func scopeString(for scope: SDKScope, operation: Operation) -> String {
        let scopeName: String
        switch scope {
        case .tasks: scopeName = "workspace.tasks"
        case .notes: scopeName = "workspace.notes"
        case .calendar: scopeName = "workspace.calendar"
        case .files: scopeName = "workspace.files"
        case .emails: scopeName = "workspace.mail"
        case .whiteboards: scopeName = "workspace.whiteboards"
        case .plugins: scopeName = "workspace.plugins"
        case .slides: scopeName = "workspace.slides"
        case .media: scopeName = "workspace.media"
        case .meet: scopeName = "workspace.meet"
        case .repos: scopeName = "workspace.repos"
        case .automations: scopeName = "workspace.automation"
        case .intelligence: scopeName = "workspace.intelligence"
        case .persona: scopeName = "workspace.persona"
        case .all: scopeName = "workspace"
        case .custom: scopeName = "workspace.custom"
        }
        return "\(scopeName).\(operation.rawValue)"
    }

    private func recordAudit(scope: String, operation: Operation, granted: Bool, reason: String?) {
        let entry = ScopeAuditEntry(scope: scope, operation: operation, granted: granted, reason: reason)
        scopeAuditLog.insert(entry, at: 0)
        if scopeAuditLog.count > maxAuditEntries {
            scopeAuditLog = Array(scopeAuditLog.prefix(maxAuditEntries))
        }

        if !granted {
            SDKLogStore.shared.log("Scope denied: \(scope) [\(operation.rawValue)]", source: "SDKScopeManager", level: LogLevel.warning)
        }
    }

    private func persistScopes() {
        let scopeArray = Array(authorizedScopes)
        if let data = try? JSONEncoder().encode(scopeArray) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func loadAuthorizedScopes() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let scopes = try? JSONDecoder().decode([String].self, from: data) {
            authorizedScopes = Set(scopes)
        }
    }
}
