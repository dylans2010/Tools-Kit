import Foundation
import Combine

@MainActor
public final class SDKConnectorManager: ObservableObject {
    public static let shared = SDKConnectorManager()

    @Published public var connectors: [any BaseConnector] = []

    private let persistenceKey = "sdk_connector_configs"

    private init() {
        loadConnectors()
    }

    public func register(_ connector: any BaseConnector) {
        guard !connectors.contains(where: { $0.id == connector.id }) else { return }
        connectors.append(connector)
        saveConnectors()
        SDKLogStore.shared.log("Connector registered: \(connector.name)", source: "SDKConnectorManager", level: LogLevel.info)
    }

    public func remove(id: UUID) {
        if let connector = connectors.first(where: { $0.id == id }) {
            connector.disconnect()
            SDKLogStore.shared.log("Connector removed: \(connector.name)", source: "SDKConnectorManager", level: LogLevel.info)
        }
        connectors.removeAll { $0.id == id }
        saveConnectors()
    }

    public func syncAll() async throws {
        guard !connectors.isEmpty else { return }

        SDKLogStore.shared.log("Starting sync for \(connectors.count) connectors", source: "SDKConnectorManager", level: LogLevel.info)

        try await withThrowingTaskGroup(of: Void.self) { group in
            for connector in connectors where connector.status == .connected {
                group.addTask {
                    try await connector.sync()
                }
            }
            try await group.waitForAll()
        }

        SDKLogStore.shared.log("All connector syncs completed", source: "SDKConnectorManager", level: LogLevel.info)
    }

    public func status(for id: UUID) -> ConnectorStatus {
        return connectors.first(where: { $0.id == id })?.status ?? .disconnected
    }

    public func connector(for id: UUID) -> (any BaseConnector)? {
        return connectors.first(where: { $0.id == id })
    }

    public func connectors(ofType type: ConnectorType) -> [any BaseConnector] {
        return connectors.filter { $0.type == type }
    }

    private func saveConnectors() {
        SDKProjectManager.shared.currentProject?.enabledConnectorIDs = connectors.map { $0.id }
        try? SDKProjectManager.shared.save()

        let configs = connectors.map { ConnectorConfig(id: $0.id, name: $0.name, type: $0.type) }
        if let data = try? JSONEncoder().encode(configs) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func loadConnectors() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let configs = try? JSONDecoder().decode([ConnectorConfig].self, from: data) else { return }

        for config in configs {
            let connector: (any BaseConnector)?
            switch config.type {
            case .gmail: connector = GmailConnector()
            case .github: connector = GitHubConnector()
            case .webhook: connector = WebhookConnector()
            case .calendar: connector = CalendarConnector()
            case .localFileSystem: connector = LocalFileConnector()
            }
            if let connector = connector {
                connectors.append(connector)
            }
        }
    }
}

private struct ConnectorConfig: Codable {
    let id: UUID
    let name: String
    let type: ConnectorType
}
