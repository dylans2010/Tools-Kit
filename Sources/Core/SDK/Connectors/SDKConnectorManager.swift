import Foundation

@MainActor
public final class SDKConnectorManager: ObservableObject {
    public static let shared = SDKConnectorManager()

    @Published public var connectors: [any BaseConnector] = []

    private init() {
        // Load connectors from CoreData/Storage
    }

    public func register(_ connector: any BaseConnector) {
        connectors.append(connector)
        SDKLogStore.shared.log("Registered connector: \(connector.name)", source: "SDKConnectorManager", level: .info)
    }

    public func remove(id: UUID) {
        connectors.removeAll { $0.id == id }
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
        return connectors.first { $0.id == id }?.status ?? .disconnected
    }
}
