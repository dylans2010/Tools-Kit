import Foundation
import Combine

@MainActor
public final class SDKConnectorEngine: ObservableObject {
    public static let shared = SDKConnectorEngine()

    @Published public var connectorHealth: [UUID: ConnectorHealthInfo] = [:]
    @Published public var syncInProgress = false

    private var backgroundSyncTimers: [UUID: AnyCancellable] = [:]
    private let maxSyncRetries = 3
    private let policyEngine = SDKPolicyEngine.shared
    private let securityManager = SDKSecurityManager.shared
    private let auditLogger = SDKAuditLogger.shared

    public struct ConnectorHealthInfo {
        public let connectorID: UUID
        public let name: String
        public let status: ConnectorStatus
        public let lastSyncAt: Date?
        public let lastError: String?
        public let responseTime: TimeInterval?
    }

    private init() {}

    // MARK: - Connect

    public func connect(connector: any BaseConnector, credentials: [String: String]) async throws {
        try validateConnectorConfiguration(connector)
        SDKLogStore.shared.log("Connecting \(connector.name)...", source: "SDKConnectorEngine", level: LogLevel.info)

        do {
            _ = try await SDKRateLimiter.shared.enforce(
                key: "connector.connect.\(connector.id.uuidString)",
                rule: .init(requestsPerMinute: 60, dataFetchLimit: 1000, executionFrequencyCap: 60)
            )
            try await connector.authenticate(credentials: credentials)
            SDKConnectorManager.shared.register(connector)
            await updateHealth(for: connector)
            auditLogger.log(eventType: .externalAPICall, projectID: SDKProjectManager.shared.currentProject?.id, scope: "external.api.unrestricted", message: "Connector connected: \(connector.name)")
            SDKLogStore.shared.log("\(connector.name) connected successfully", source: "SDKConnectorEngine", level: LogLevel.info)
        } catch {
            auditLogger.log(eventType: .externalAPICall, projectID: SDKProjectManager.shared.currentProject?.id, scope: "external.api.unrestricted", message: "Connector connect failed: \(connector.name)", metadata: ["error": error.localizedDescription])
            SDKLogStore.shared.log("\(connector.name) connection failed: \(error.localizedDescription)", source: "SDKConnectorEngine", level: LogLevel.error)
            throw error
        }
    }

    // MARK: - Sync All

    public func syncAll() async throws {
        syncInProgress = true
        defer { syncInProgress = false }

        let connectors = SDKConnectorManager.shared.connectors

        try await withThrowingTaskGroup(of: Void.self) { group in
            for connector in connectors {
                group.addTask {
                    try await self.syncWithRetry(connector: connector)
                }
            }
            try await group.waitForAll()
        }

        SDKLogStore.shared.log("All connectors synced", source: "SDKConnectorEngine", level: LogLevel.info)
    }

    // MARK: - Sync Individual

    public func sync(connectorID: UUID) async throws {
        guard let connector = SDKConnectorManager.shared.connectors.first(where: { $0.id == connectorID }) else {
            throw SDKError.executionFailed(reason: "Connector not found")
        }

        try await syncWithRetry(connector: connector)
    }

    // MARK: - Background Sync

    public func enableBackgroundSync(connectorID: UUID, interval: TimeInterval = 300) {
        backgroundSyncTimers[connectorID]?.cancel()

        backgroundSyncTimers[connectorID] = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    try? await self?.sync(connectorID: connectorID)
                }
            }

        SDKLogStore.shared.log("Background sync enabled for \(connectorID) every \(interval)s", source: "SDKConnectorEngine", level: LogLevel.info)
    }

    public func disableBackgroundSync(connectorID: UUID) {
        backgroundSyncTimers[connectorID]?.cancel()
        backgroundSyncTimers.removeValue(forKey: connectorID)
    }

    // MARK: - Health

    public func checkHealth() async -> [ConnectorHealthInfo] {
        var healthInfos: [ConnectorHealthInfo] = []

        for connector in SDKConnectorManager.shared.connectors {
            let start = Date()
            let reachable: Bool
            do {
                reachable = try await connector.testConnection()
            } catch {
                reachable = false
            }
            let responseTime = Date().timeIntervalSince(start)

            let info = ConnectorHealthInfo(
                connectorID: connector.id,
                name: connector.name,
                status: reachable ? .connected : .error,
                lastSyncAt: Date(),
                lastError: reachable ? nil : "Connection test failed",
                responseTime: responseTime
            )
            healthInfos.append(info)
            connectorHealth[connector.id] = info
        }

        return healthInfos
    }

    // MARK: - Private

    private func syncWithRetry(connector: any BaseConnector) async throws {
        var lastError: Error?

        for attempt in 0..<maxSyncRetries {
            do {
                try enforceConnectorPolicy(connector: connector, operation: "sync")
                try await connector.sync()
                await updateHealth(for: connector)
                auditLogger.log(eventType: .externalAPICall, projectID: SDKProjectManager.shared.currentProject?.id, scope: "external.api.unrestricted", message: "Connector sync succeeded: \(connector.name)")
                return
            } catch {
                lastError = error
                if attempt < maxSyncRetries - 1 {
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    SDKLogStore.shared.log("\(connector.name) sync retry \(attempt + 1)/\(maxSyncRetries)", source: "SDKConnectorEngine", level: LogLevel.warning)
                }
            }
        }

        SDKLogStore.shared.log("\(connector.name) sync failed after \(maxSyncRetries) attempts", source: "SDKConnectorEngine", level: LogLevel.error)
        auditLogger.log(eventType: .externalAPICall, projectID: SDKProjectManager.shared.currentProject?.id, scope: "external.api.unrestricted", message: "Connector sync failed: \(connector.name)", metadata: ["error": lastError?.localizedDescription ?? "Unknown"])
        throw lastError ?? SDKError.executionFailed(reason: "Sync failed")
    }

    private func updateHealth(for connector: any BaseConnector) async {
        let reachable: Bool
        do {
            reachable = try await connector.testConnection()
        } catch {
            reachable = false
        }

        connectorHealth[connector.id] = ConnectorHealthInfo(
            connectorID: connector.id,
            name: connector.name,
            status: reachable ? connector.status : .error,
            lastSyncAt: Date(),
            lastError: reachable ? nil : "Unreachable",
            responseTime: nil
        )
    }

    private func validateConnectorConfiguration(_ connector: any BaseConnector) throws {
        guard !connector.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SDKError.validationError(reason: "Connector name is required")
        }
    }

    private func enforceConnectorPolicy(connector: any BaseConnector, operation: String) throws {
        let request = SDKPolicyRequest(
            operationName: "connector.\(operation)",
            scope: "external.api.unrestricted",
            projectID: SDKProjectManager.shared.currentProject?.id,
            actorID: "connector-engine",
            apiKey: nil,
            allowedScopes: ["external.api.unrestricted", "*"],
            justification: "Connector operation \(operation)",
            privacyNote: "Connector operation \(operation)"
        )
        let decision = try policyEngine.evaluate(request)
        try securityManager.enforce(request: request, definition: decision.scopeDefinition)
    }
}
