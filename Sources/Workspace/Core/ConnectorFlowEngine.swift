import Foundation

final class ConnectorFlowEngine {
    static let shared = ConnectorFlowEngine()

    private init() {}

    func executeFlow(_ flow: ConnectorFlow, connector: ConnectorDefinition, initialPayload: [String: Any] = [:]) {
        Task {
            var currentPayload = initialPayload
            print("[ConnectorFlowEngine] Starting flow: \(flow.name)")

            for step in flow.steps {
                do {
                    currentPayload = try await executeStep(step, connector: connector, payload: currentPayload)
                } catch {
                    print("[ConnectorFlowEngine] Error executing step \(step.id): \(error)")
                    // Handle retries or failure rules here
                    break
                }
            }
            print("[ConnectorFlowEngine] Flow \(flow.name) completed.")
        }
    }

    private func executeStep(_ step: FlowStep, connector: ConnectorDefinition, payload: [String: Any]) async throws -> [String: Any] {
        switch step.type {
        case .apiCall:
            guard let endpointID = step.endpointID,
                  let endpoint = connector.endpoints.first(where: { $0.id == endpointID }) else {
                throw FlowError.missingEndpoint
            }

            let (data, _) = try await ConnectorExecutionService.shared.performRequest(endpoint: endpoint, connector: connector)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            return json

        case .transformation:
            if let transformation = step.transformation {
                print("[ConnectorFlowEngine] Applying transformation: \(transformation)")
                // In production, this would use JSContext to apply the transformation
            }
            return payload

        case .condition:
            if let condition = step.condition {
                print("[ConnectorFlowEngine] Evaluating condition: \(condition)")
                // If condition fails, we might throw or return empty
            }
            return payload

        case .notification:
            print("[ConnectorFlowEngine] Notification step triggered")
            NotificationCenter.default.post(name: NSNotification.Name("com.toolskit.connector.notification"), object: nil, userInfo: ["message": "Flow step executed"])
            return payload

        case .script:
            print("[ConnectorFlowEngine] Running script step")
            return payload
        }
    }
}

enum FlowError: Error {
    case missingEndpoint
}
