import Foundation
import Combine

// MARK: - SDK Data Types

public struct SDKDataItem: Identifiable, Codable {
    public let id: UUID
    public let scope: SDKScope
    public let title: String
    public let codablePayload: [String: String]
    public let timestamp: Date

    public var payload: [String: Any] { codablePayload.reduce(into: [:]) { $0[$1.key] = $1.value } }

    public init(id: UUID, scope: SDKScope, title: String, payload: [String: Any], timestamp: Date) {
        self.id = id
        self.scope = scope
        self.title = title
        self.codablePayload = payload.reduce(into: [:]) { $0[$1.key] = String(describing: $1.value) }
        self.timestamp = timestamp
    }
}

public enum SDKScope: Hashable, CaseIterable, Codable {
    case all, tasks, notes, calendar, files, emails, whiteboards, plugins
    case slides, media, meet, repos, automations, intelligence, persona
    case custom(query: String)

    public static var allCases: [SDKScope] {
        return [.all, .tasks, .notes, .calendar, .files, .emails, .whiteboards,
                .plugins, .slides, .media, .meet, .repos, .automations,
                .intelligence, .persona]
    }

    private enum CodingKeys: String, CodingKey {
        case type, query
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "all": self = .all
        case "tasks": self = .tasks
        case "notes": self = .notes
        case "calendar": self = .calendar
        case "files": self = .files
        case "emails": self = .emails
        case "whiteboards": self = .whiteboards
        case "plugins": self = .plugins
        case "slides": self = .slides
        case "media": self = .media
        case "meet": self = .meet
        case "repos": self = .repos
        case "automations": self = .automations
        case "intelligence": self = .intelligence
        case "persona": self = .persona
        case "custom":
            let query = try container.decode(String.self, forKey: .query)
            self = .custom(query: query)
        default:
            self = .all
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .all: try container.encode("all", forKey: .type)
        case .tasks: try container.encode("tasks", forKey: .type)
        case .notes: try container.encode("notes", forKey: .type)
        case .calendar: try container.encode("calendar", forKey: .type)
        case .files: try container.encode("files", forKey: .type)
        case .emails: try container.encode("emails", forKey: .type)
        case .whiteboards: try container.encode("whiteboards", forKey: .type)
        case .plugins: try container.encode("plugins", forKey: .type)
        case .slides: try container.encode("slides", forKey: .type)
        case .media: try container.encode("media", forKey: .type)
        case .meet: try container.encode("meet", forKey: .type)
        case .repos: try container.encode("repos", forKey: .type)
        case .automations: try container.encode("automations", forKey: .type)
        case .intelligence: try container.encode("intelligence", forKey: .type)
        case .persona: try container.encode("persona", forKey: .type)
        case .custom(let query):
            try container.encode("custom", forKey: .type)
            try container.encode(query, forKey: .query)
        }
    }

    var cacheKey: String {
        switch self {
        case .custom(let query): return "custom_\(query)"
        default: return String(describing: self)
        }
    }
}

// MARK: - SDK Query Types

public struct SDKQuery {
    public var scope: SDKScope
    public var filters: [SDKFilter]
    public var pagination: SDKPagination?
    public var streaming: Bool
    public var partialDataset: Bool

    public init(scope: SDKScope, filters: [SDKFilter] = [], pagination: SDKPagination? = nil, streaming: Bool = false, partialDataset: Bool = false) {
        self.scope = scope
        self.filters = filters
        self.pagination = pagination
        self.streaming = streaming
        self.partialDataset = partialDataset
    }
}

public struct SDKFilter {
    public enum FilterType {
        case date(from: Date?, to: Date?)
        case tags([String])
        case ownership(String)
        case type(String)
        case keyword(String)
    }

    public let type: FilterType

    public init(_ type: FilterType) {
        self.type = type
    }
}

public struct SDKPagination {
    public var page: Int
    public var pageSize: Int

    public init(page: Int = 1, pageSize: Int = 50) {
        self.page = page
        self.pageSize = pageSize
    }
}

public struct SDKBatchResult {
    public let succeeded: Int
    public let failed: Int
    public let errors: [Error]
}

public struct SDKWriteResult {
    public let id: UUID
    public let scope: SDKScope
    public let success: Bool
}

// MARK: - ToolsKitSDK Central Orchestrator

@MainActor
public final class ToolsKitSDK: ObservableObject {
    public static let shared = ToolsKitSDK()

    @Published public var isSyncing = false
    @Published public var isInitialized = false

    private let dataEngine = SDKDataEngine.shared
    private let scopeManager = SDKScopeManager.shared
    private let eventBridge = SDKEventBridge.shared
    private let realtimeSync = SDKRealtimeSync.shared
    private let storageManager = SDKStorageManager.shared
    private let networkManager = SDKNetworkManager.shared
    private let graphInterface = SDKGraphInterface.shared
    private let personaBridge = SDKPersonaBridge.shared
    private let timeTravelBridge = SDKTimeTravelBridge.shared
    private let executionEngine = SDKExecutionEngine.shared
    private let connectorEngine = SDKConnectorEngine.shared
    private let toolRuntime = SDKToolRuntime.shared
    private let securityManager = SDKSecurityManager.shared
    private let privacyManager = SDKPrivacyManager.shared
    private let policyEngine = SDKPolicyEngine.shared
    private let auditLogger = SDKAuditLogger.shared
    private let projectManager = SDKProjectManager.shared
    private let authorizationManager = AuthorizationManager.shared

    private init() {
        initialize()
    }

    private func initialize() {
        Task {
            await SDKLogStore.shared.log("ToolsKitSDK initializing", source: "ToolsKitSDK", level: .info)
            await SDKLogStore.shared.log("ToolsKitSDK ready", source: "ToolsKitSDK", level: .info)
        }
        isInitialized = true
    }

    // MARK: - 1. sdk.fetchData

    public func fetchData(scope: SDKScope) async throws -> [SDKDataItem] {
        let scopeName = scope == .all ? "sdk.fetchData.full" : "workspace.\(String(describing: scope))"
        return try await runGovernedCall(
            operationName: "sdk.fetchData",
            scopeName: scopeName,
            eventType: .dataAccess,
            fetchUnits: 1
        ) {
            try self.scopeManager.validateAccess(scope: scope, operation: .read)
            await SDKLogStore.shared.log("fetchData scope=\(scope)", source: "ToolsKitSDK", level: .info)
            let raw = try await self.dataEngine.fetch(scope: scope)
            return raw.map { item in
                let redacted = self.privacyManager.redactRestrictedFields(item.payload, scope: scopeName)
                return SDKDataItem(id: item.id, scope: item.scope, title: item.title, payload: redacted, timestamp: item.timestamp)
            }
        }
    }

    public func fetchData(query: SDKQuery) async throws -> [SDKDataItem] {
        let scopeName = query.scope == .all ? "sdk.fetchData.full" : "workspace.\(String(describing: query.scope))"
        return try await runGovernedCall(
            operationName: "sdk.fetchData.query",
            scopeName: scopeName,
            eventType: .dataAccess,
            fetchUnits: query.pagination?.pageSize ?? 1
        ) {
            try self.scopeManager.validateAccess(scope: query.scope, operation: .read)
            let raw = try await self.dataEngine.fetch(query: query)
            return raw.map { item in
                let redacted = self.privacyManager.redactRestrictedFields(item.payload, scope: scopeName)
                return SDKDataItem(id: item.id, scope: item.scope, title: item.title, payload: redacted, timestamp: item.timestamp)
            }
        }
    }

    // MARK: - 2. sdk.writeData

    public func writeData(scope: SDKScope, title: String, payload: [String: Any]) async throws -> SDKWriteResult {
        try await runGovernedCall(
            operationName: "sdk.writeData",
            scopeName: "workspace.\(String(describing: scope))",
            eventType: .dataAccess
        ) {
            try self.scopeManager.validateAccess(scope: scope, operation: .write)
            let sanitized = self.privacyManager.redactRestrictedFields(payload, scope: "workspace.\(String(describing: scope))")
            let result = try await self.dataEngine.write(scope: scope, title: title, payload: sanitized)
            self.eventBridge.emit(type: "data.written", payload: ["scope": "\(scope)", "title": title])
            return result
        }
    }

    // MARK: - 3. sdk.deleteData

    public func deleteData(scope: SDKScope, id: UUID) async throws {
        try await runGovernedCall(
            operationName: "sdk.deleteData",
            scopeName: "workspace.\(String(describing: scope))",
            eventType: .dataAccess
        ) {
            try self.scopeManager.validateAccess(scope: scope, operation: .delete)
            try await self.dataEngine.delete(scope: scope, id: id)
            self.eventBridge.emit(type: "data.deleted", payload: ["scope": "\(scope)", "id": id.uuidString])
        }
    }

    // MARK: - 4. sdk.batchUpdate

    public func batchUpdate(operations: [(scope: SDKScope, title: String, payload: [String: Any])]) async throws -> SDKBatchResult {
        var succeeded = 0
        var failed = 0
        var errors: [Error] = []

        for operation in operations {
            do {
                try scopeManager.validateAccess(scope: operation.scope, operation: .write)
                _ = try await dataEngine.write(scope: operation.scope, title: operation.title, payload: operation.payload)
                succeeded += 1
            } catch {
                failed += 1
                errors.append(error)
            }
        }

        await SDKLogStore.shared.log("batchUpdate: \(succeeded) succeeded, \(failed) failed", source: "ToolsKitSDK", level: .info)
        return SDKBatchResult(succeeded: succeeded, failed: failed, errors: errors)
    }

    // MARK: - 5. sdk.cacheLayer

    public func cacheLayer(scope: SDKScope) -> SDKCacheInfo {
        return dataEngine.cacheInfo(for: scope)
    }

    public func invalidateCache(scope: SDKScope? = nil) {
        dataEngine.invalidateCache(scope: scope)
    }

    // MARK: - 6. sdk.localStorage

    public func localStorage(key: String) -> Any? {
        return storageManager.getValue(key: key)
    }

    public func setLocalStorage(key: String, value: Any) {
        storageManager.setValue(key: key, value: value)
    }

    // MARK: - 7. sdk.secureStorage

    public func secureStorage(key: String) -> String? {
        return storageManager.getSecureValue(key: key)
    }

    public func setSecureStorage(key: String, value: String) throws {
        try storageManager.setSecureValue(key: key, value: value)
    }

    // MARK: - 8. sdk.subscribeEvent

    public func subscribeEvent(type: String, handler: @escaping (SDKEvent) -> Void) -> AnyCancellable {
        return eventBridge.subscribe(type: type, handler: handler)
    }

    // MARK: - 9. sdk.emitEvent

    public func emitEvent(type: String, payload: [String: Any]) {
        eventBridge.emit(type: type, payload: payload)
    }

    // MARK: - 10. sdk.replayEvents

    public func replayEvents(from: Date, to: Date) -> [SDKEvent] {
        return eventBridge.replay(from: from, to: to)
    }

    // MARK: - 11. sdk.filterEvents

    public func filterEvents(type: String?, source: String?) -> [SDKEvent] {
        return eventBridge.filter(type: type, source: source)
    }

    // MARK: - 12. sdk.ai.generate

    public func aiGenerate(prompt: String, context: [String: Any] = [:]) async throws -> String {
        try scopeManager.validateAccess(scope: .persona, operation: .read)
        return try await personaBridge.generate(prompt: prompt, context: context)
    }

    // MARK: - 13. sdk.ai.analyze

    public func aiAnalyze(data: [SDKDataItem], prompt: String) async throws -> String {
        try scopeManager.validateAccess(scope: .persona, operation: .read)
        return try await personaBridge.analyze(data: data, prompt: prompt)
    }

    // MARK: - 14. sdk.ai.summarize

    public func aiSummarize(items: [SDKDataItem]) async throws -> String {
        try scopeManager.validateAccess(scope: .persona, operation: .read)
        return try await personaBridge.summarize(items: items)
    }

    // MARK: - 15. sdk.persona.query

    public func personaQuery(prompt: String) async throws -> String {
        try scopeManager.validateAccess(scope: .persona, operation: .read)
        return try await personaBridge.queryPersona(prompt: prompt)
    }

    // MARK: - 16. sdk.persona.memory.write

    public func personaMemoryWrite(entityID: UUID, memory: String) async throws {
        try scopeManager.validateAccess(scope: .persona, operation: .write)
        try await personaBridge.writeMemory(entityID: entityID, memory: memory)
    }

    // MARK: - 17. sdk.automation.trigger

    public func automationTrigger(event: String, context: [String: Any] = [:]) async {
        await SDKAutomationEngine.shared.evaluate(trigger: .dataUpdated(scope: event), context: context)
        eventBridge.emit(type: "automation.triggered", payload: ["event": event])
    }

    // MARK: - 18. sdk.automation.createWorkflow

    public func automationCreateWorkflow(rule: SDKAutomationRule) {
        SDKAutomationEngine.shared.add(rule)
        Task {
            await SDKLogStore.shared.log("Workflow created: \(rule.name)", source: "ToolsKitSDK", level: .info)
        }
    }

    // MARK: - 19. sdk.automation.modify

    public func automationModify(ruleID: UUID, updates: (inout SDKAutomationRule) -> Void) {
        guard var rule = SDKAutomationEngine.shared.rules.first(where: { $0.id == ruleID }) else { return }
        updates(&rule)
        SDKAutomationEngine.shared.remove(id: ruleID)
        SDKAutomationEngine.shared.add(rule)
    }

    // MARK: - 20. sdk.external.connect

    public func externalConnect(connector: any BaseConnector, credentials: [String: String]) async throws {
        try await runGovernedCall(
            operationName: "sdk.external.connect",
            scopeName: "external.api.unrestricted",
            eventType: .externalAPICall
        ) {
            try await self.connectorEngine.connect(connector: connector, credentials: credentials)
        }
    }

    // MARK: - 21. sdk.external.fetch

    public func externalFetch(url: String, headers: [String: String] = [:]) async throws -> Data {
        try await runGovernedCall(
            operationName: "sdk.external.fetch",
            scopeName: "external.api.unrestricted",
            eventType: .externalAPICall
        ) {
            try await self.networkManager.fetch(url: url, headers: headers)
        }
    }

    // MARK: - 22. sdk.external.webhook

    public func externalWebhook(url: String, payload: [String: Any], apiKey: String? = nil) async throws -> Data {
        try await runGovernedCall(
            operationName: "sdk.external.webhook",
            scopeName: "external.api.unrestricted",
            apiKey: apiKey,
            eventType: .externalAPICall
        ) {
            let sanitized = self.privacyManager.redactRestrictedFields(payload, scope: "external.api.unrestricted")
            return try await self.networkManager.postWebhook(url: url, payload: sanitized, apiKey: apiKey)
        }
    }

    // MARK: - 23. sdk.external.sync

    public func externalSync() async throws {
        try await runGovernedCall(
            operationName: "sdk.external.sync",
            scopeName: "external.api.unrestricted",
            eventType: .externalAPICall
        ) {
            self.isSyncing = true
            defer { self.isSyncing = false }
            try await self.connectorEngine.syncAll()
        }
    }

    // MARK: - 24. sdk.realtime.subscribe

    public func realtimeSubscribe(channel: String, handler: @escaping ([String: Any]) -> Void) -> AnyCancellable {
        return realtimeSync.subscribe(channel: channel, handler: handler)
    }

    // MARK: - 25. sdk.realtime.broadcast

    public func realtimeBroadcast(channel: String, data: [String: Any]) {
        realtimeSync.broadcast(channel: channel, data: data)
    }

    // MARK: - 26. sdk.graph.query

    internal func graphQuery(entityType: String?, relation: String?) -> SDKGraph {
        return graphInterface.query(entityType: entityType, relation: relation)
    }

    // MARK: - 27. sdk.graph.linkEntities

    public func graphLinkEntities(source: UUID, target: UUID, relation: String) {
        graphInterface.linkEntities(source: source, target: target, relation: relation)
        eventBridge.emit(type: "graph.linked", payload: ["source": source.uuidString, "target": target.uuidString, "relation": relation])
    }

    // MARK: - 28. sdk.time.getHistory

    internal func timeGetHistory(scope: SDKScope?, from: Date?, to: Date?) -> [WorkspaceSnapshot] {
        return timeTravelBridge.getHistory(scope: scope, from: from, to: to)
    }

    // MARK: - 29. sdk.time.restore

    public func timeRestore(snapshotID: UUID) throws {
        try timeTravelBridge.restore(snapshotID: snapshotID)
        eventBridge.emit(type: "time.restored", payload: ["snapshotID": snapshotID.uuidString])
    }

    // MARK: - 30. sdk.time.diff

    public func timeDiff(snapshotA: UUID, snapshotB: UUID) -> [String: Any] {
        return timeTravelBridge.diff(snapshotA: snapshotA, snapshotB: snapshotB)
    }

    // MARK: - 31. sdk.ui.renderComponent

    public func uiRenderComponent(name: String, props: [String: Any]) {
        eventBridge.emit(type: "ui.render", payload: ["component": name, "props": props.reduce(into: [:]) { $0[$1.key] = String(describing: $1.value) }])
    }

    // MARK: - 32. sdk.ui.injectPanel

    public func uiInjectPanel(position: String, content: String) {
        eventBridge.emit(type: "ui.injectPanel", payload: ["position": position, "content": content])
    }

    // MARK: - 33. sdk.ui.triggerAction

    public func uiTriggerAction(actionID: String, context: [String: Any] = [:]) {
        eventBridge.emit(type: "ui.action", payload: ["actionID": actionID])
    }

    // MARK: - 34. sdk.validateScope

    public func validateScope(scope: SDKScope, operation: SDKScopeManager.Operation) -> Bool {
        do {
            try scopeManager.validateAccess(scope: scope, operation: operation)
            return true
        } catch {
            return false
        }
    }

    // MARK: - 35. sdk.auditLog

    public func auditLog(entries: Int = 100) -> [SDKLogEntry] {
        return Array(SDKLogStore.shared.entries.prefix(entries))
    }

    public func auditLog(source: String) -> [SDKLogEntry] {
        return SDKLogStore.shared.entries(for: source)
    }

    // MARK: - Plugin Registration

    public func registerPlugin(_ plugin: SDKPlugin) throws {
        try SDKPluginManager.shared.install(plugin)
        eventBridge.emit(type: "plugin.registered", payload: ["name": plugin.name])
    }

    // MARK: - Tool Execution

    public func executeTool(toolID: UUID, input: [String: Any] = [:]) async throws -> SDKToolResult {
        return try await toolRuntime.execute(toolID: toolID, input: input)
    }

    // MARK: - Automation Execution

    public func runAutomation(_ rule: SDKAutomationRule) async throws {
        SDKAutomationEngine.shared.add(rule)
        try await SDKAutomationEngine.shared.run(rule: rule, context: [:])
    }

    // MARK: - Connector Sync

    public func syncConnectors() async throws {
        try await runGovernedCall(
            operationName: "sdk.syncConnectors",
            scopeName: "external.api.unrestricted",
            eventType: .externalAPICall
        ) {
            self.isSyncing = true
            defer { self.isSyncing = false }
            try await self.connectorEngine.syncAll()
        }
    }

    // MARK: - Developer NoSandbox Mode

    public var developer: SDKDeveloperAPI { SDKDeveloperAPI() }

    public struct SDKDeveloperAPI {
        public var noSandbox: SDKNoSandboxAPI { SDKNoSandboxAPI() }

        public struct SDKNoSandboxAPI {
            public var isEnabled: Bool {
                SDKRuntimeEngine.shared.isNoSandboxModeEnabled
            }

            public func enable() {
                SDKRuntimeEngine.shared.isNoSandboxModeEnabled = true
                Task {
                    await SDKLogStore.shared.log("NoSandbox mode ENABLED - all scope restrictions bypassed", source: "SDK.Developer", level: .warning)
                }
            }

            public func disable() {
                SDKRuntimeEngine.shared.isNoSandboxModeEnabled = false
                Task {
                    await SDKLogStore.shared.log("NoSandbox mode DISABLED", source: "SDK.Developer", level: .info)
                }
            }
        }
    }
}

extension ToolsKitSDK {
    private func runGovernedCall<T>(
        operationName: String,
        scopeName: String,
        apiKey: String? = nil,
        eventType: SDKAuditLogger.Event.EventType = .execution,
        fetchUnits: Int = 0,
        block: @escaping () async throws -> T
    ) async throws -> T {
        let project = projectManager.currentProject
        let allowedScopes = Set(project?.enabledScopes ?? []).union(Set(project?.requiredScopes ?? []))
        let request = SDKPolicyRequest(
            operationName: operationName,
            scope: scopeName,
            projectID: project?.id,
            actorID: "workspace-user",
            apiKey: apiKey,
            allowedScopes: allowedScopes.isEmpty ? ["*"] : allowedScopes,
            justification: project?.description,
            privacyNote: project?.description
        )

        guard authorizationManager.validateScope(scopeName) else {
            throw SDKError.permissionDenied(scope: scopeName)
        }

        do {
            let decision = try policyEngine.evaluate(request)
            try securityManager.enforce(request: request, definition: decision.scopeDefinition)
            _ = try await SDKRateLimiter.shared.enforce(
                key: "\(request.actorID):\(project?.id.uuidString ?? "global"):\(scopeName)",
                rule: decision.rateRule,
                fetchUnits: fetchUnits,
                executions: 1
            )
            auditLogger.log(
                eventType: .scopeUsage,
                projectID: project?.id,
                scope: scopeName,
                message: "Policy approved \(operationName)"
            )
            return try await executionEngine.executeGovernedOperation(
                name: operationName,
                scope: scopeName,
                projectID: project?.id,
                operation: block
            )
        } catch {
            auditLogger.log(
                eventType: eventType,
                projectID: project?.id,
                scope: scopeName,
                message: "Governed call blocked: \(operationName)",
                metadata: ["error": error.localizedDescription]
            )
            throw error
        }
    }
}

// MARK: - Workspace Data Models


public struct SDKCacheInfo {
    public let scope: SDKScope
    public let itemCount: Int
    public let lastRefreshed: Date?
    public let isValid: Bool
    public let ttlRemaining: TimeInterval
}
