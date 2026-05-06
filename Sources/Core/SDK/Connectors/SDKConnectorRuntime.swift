import Foundation

/// Executes connector logic and manages external API state.
public final class SDKConnectorRuntime {
    public static let shared = SDKConnectorRuntime()

    private init() {}

    public func executeSync(connectorID: UUID) async throws {
        guard let connector = await SDKConnectorManager.shared.connectors.first(where: { $0.id == connectorID }) else {
            throw SDKError.executionFailed(reason: "Connector \(connectorID) not found")
        }

        SDKLogStore.shared.log("Starting sync for connector: \(connector.name)", source: "SDKConnectorRuntime", level: .info)
        try await connector.sync()
    }
}
