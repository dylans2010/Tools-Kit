import Foundation
import Combine

@MainActor
public final class SDKConnectorManager: ObservableObject {
    public static let shared = SDKConnectorManager()

    @Published public var connectors: [any BaseConnector] = []

    private init() {
        loadConnectors()
    }

    public func register(_ connector: any BaseConnector) {
        connectors.append(connector)
        saveConnectors()
    }

    public func remove(id: UUID) {
        connectors.removeAll { $0.id == id }
        saveConnectors()
    }

    public func syncAll() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for connector in connectors {
                group.addTask {
                    try await connector.sync()
                }
            }
            try await group.waitForAll()
        }
    }

    public func status(for id: UUID) -> ConnectorStatus {
        return connectors.first(where: { $0.id == id })?.status ?? .disconnected
    }

    private func saveConnectors() {
        // Logic to persist connector configurations to CoreData
        // For now, using SDKProjectManager to track enabled IDs
        SDKProjectManager.shared.currentProject?.enabledConnectorIDs = connectors.map { $0.id }
        try? SDKProjectManager.shared.save()
    }

    private func loadConnectors() {
        // In a real implementation, we would re-instantiate connectors from CoreData/Keychain
    }
}
