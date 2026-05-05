import Foundation

final class ConnectorRuntime {
    static let shared = ConnectorRuntime()

    private let executionService = ConnectorExecutionService.shared
    private let flowEngine = ConnectorFlowEngine.shared

    private init() {}

    func executeConnector(_ connector: ConnectorDefinition) {
        guard connector.isEnabled else { return }
        print("[ConnectorRuntime] Executing connector: \(connector.name)")

        // Connectors usually respond to triggers, but can be manually triggered
        for flow in connector.flows {
            if flow.trigger.type == .manual {
                flowEngine.executeFlow(flow, connector: connector)
            }
        }
    }

    func handleWebhook(identifier: String, payload: [String: Any]) {
        let connectors = ConnectorManager.shared.connectors.filter { $0.isEnabled && $0.identifier == identifier }
        for connector in connectors {
            for flow in connector.flows {
                if flow.trigger.type == .webhook {
                    flowEngine.executeFlow(flow, connector: connector, initialPayload: payload)
                }
            }
        }
    }
}
