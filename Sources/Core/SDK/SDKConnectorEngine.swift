import Foundation
import Combine

@MainActor
public final class SDKConnectorEngine: ObservableObject {
    public static let shared = SDKConnectorEngine()

    @Published public var connectorHealth: [UUID: ConnectorHealthInfo] = [:]
    @Published public var syncInProgress = false

    private var backgroundSyncTimers: [UUID: AnyCancellable] = [:]
    private let maxSyncRetries = 3

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
        SDKLogStore.shared.log("Connecting \(connector.name)...", source: "SDKConnectorEngine", level: LogLevel.info)

        do {
            try await connector.authenticate(credentials: credentials)
            SDKConnectorManager.shared.register(connector)
            await updateHealth(for: connector)
            SDKLogStore.shared.log("\(connector.name) connected successfully", source: "SDKConnectorEngine", level: LogLevel.info)
        } catch {
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
                try await connector.sync()
                await updateHealth(for: connector)
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
}
