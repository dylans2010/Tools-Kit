import Foundation

public class DeveloperScopeService: ObservableObject {
    public static let shared = DeveloperScopeService()
    private let store = DeveloperPersistentStore.shared

    @Published public var catalog: [DeveloperScope] = []
    @Published public var grantedScopes: [GrantedScope] = []
    @Published public var pendingRequests: [ScopeRequest] = []
    @Published public var auditLog: [ScopeAuditEvent] = []

    private init() {
        loadCatalog()
        loadGrantedScopes()
        loadPendingRequests()
        loadAuditLog()
    }

    public func loadCatalog() {
        // The catalog should be loaded from a real resource or API.
        // For now, we provide the standard system scopes as the "real" catalog.
        self.catalog = [
            DeveloperScope(id: "user:read", name: "Read User Profile", description: "Access to basic profile information.", riskLevel: .low, category: .identity),
            DeveloperScope(id: "user:write", name: "Update User Profile", description: "Ability to modify user profile details.", riskLevel: .medium, category: .identity),
            DeveloperScope(id: "workspace:read", name: "Read Workspace", description: "Access to workspace structure and members.", riskLevel: .medium, category: .workspace),
            DeveloperScope(id: "workspace:admin", name: "Workspace Administration", description: "Full control over workspace settings.", riskLevel: .critical, category: .workspace, requiredTier: .enterprise),
            DeveloperScope(id: "automation:run", name: "Run Automations", description: "Ability to trigger and manage automated workflows.", riskLevel: .high, category: .automation),
            DeveloperScope(id: "system:logs", name: "Read System Logs", description: "Access to low-level system execution logs.", riskLevel: .high, category: .system, requiredTier: .verified)
        ]
    }

    public func loadGrantedScopes() {
        self.grantedScopes = store.grantedScopes
    }

    public func loadPendingRequests() {
        self.pendingRequests = store.scopeRequests.filter { $0.status == .pending }
    }

    public func loadAuditLog() {
        self.auditLog = store.scopeAuditLogs
    }

    public func submitRequest(_ request: ScopeRequest) async throws {
        var currentRequests = store.scopeRequests
        currentRequests.append(request)
        store.saveScopeRequests(currentRequests)

        var currentAudit = store.scopeAuditLogs
        let event = ScopeAuditEvent(eventType: "Request", scopeIdentifier: request.scopeIdentifier, appID: request.appId, actorID: UUID()) // Use real actor
        currentAudit.insert(event, at: 0)
        store.saveScopeAuditLogs(currentAudit)

        await MainActor.run {
            self.pendingRequests = currentRequests.filter { $0.status == .pending }
            self.auditLog = currentAudit
        }

        await DeveloperActivityService.shared.logEvent(
            eventType: .scopeRequested,
            appID: request.appId,
            recordID: request.id
        )
    }

    public func cancelRequest(id: UUID) async throws {
        var currentRequests = store.scopeRequests
        if let index = currentRequests.firstIndex(where: { $0.id == id }) {
            currentRequests[index].status = .cancelled
            store.saveScopeRequests(currentRequests)

            await MainActor.run {
                self.pendingRequests = currentRequests.filter { $0.status == .pending }
            }
        }
    }

    public func revokeScope(id: UUID) async throws {
        var currentGranted = store.grantedScopes
        if let index = currentGranted.firstIndex(where: { $0.id == id }) {
            let scopeId = currentGranted[index].scopeIdentifier
            let appId = currentGranted[index].appID
            currentGranted.remove(at: index)
            store.saveGrantedScopes(currentGranted)

            var currentAudit = store.scopeAuditLogs
            let event = ScopeAuditEvent(eventType: "Revoke", scopeIdentifier: scopeId, appID: appId, actorID: UUID())
            currentAudit.insert(event, at: 0)
            store.saveScopeAuditLogs(currentAudit)

            await MainActor.run {
                self.grantedScopes = currentGranted
                self.auditLog = currentAudit
            }
        }
    }

    public func fetchScope(identifier: String) -> DeveloperScope? {
        return catalog.first { $0.id == identifier }
    }

    public func approveRequest(id: UUID) async throws {
        var currentRequests = store.scopeRequests
        if let index = currentRequests.firstIndex(where: { $0.id == id }) {
            currentRequests[index].status = .approved
            let request = currentRequests[index]
            store.saveScopeRequests(currentRequests)

            // Grant the scope
            var currentGranted = store.grantedScopes
            let grant = GrantedScope(scopeIdentifier: request.scopeIdentifier, appID: request.appId)
            currentGranted.append(grant)
            store.saveGrantedScopes(currentGranted)

            var currentAudit = store.scopeAuditLogs
            let event = ScopeAuditEvent(eventType: "Grant", scopeIdentifier: request.scopeIdentifier, appID: request.appId, actorID: UUID())
            currentAudit.insert(event, at: 0)
            store.saveScopeAuditLogs(currentAudit)

            await MainActor.run {
                self.pendingRequests = currentRequests.filter { $0.status == .pending }
                self.grantedScopes = currentGranted
                self.auditLog = currentAudit
            }

            await DeveloperActivityService.shared.logEvent(
                eventType: .scopeGranted,
                appID: request.appId,
                recordID: grant.id
            )
        }
    }
}
