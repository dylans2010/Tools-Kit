import Foundation

/// Execution context for all SDK operations.
public struct SDKExecutionContext: Codable {
    public let projectID: UUID
    public let noSandbox: Bool
    public var appInstanceID: UUID?
    public var traceID: UUID
    public var parameters: [String: AnyCodable]

    public init(projectID: UUID, noSandbox: Bool = false, appInstanceID: UUID? = nil, traceID: UUID = UUID(), parameters: [String: AnyCodable] = [:]) {
        self.projectID = projectID
        self.noSandbox = noSandbox
        self.appInstanceID = appInstanceID
        self.traceID = traceID
        self.parameters = parameters
    }
}

/// Central execution orchestrator for the SDK (Upgraded).
extension SDKExecutionKernel {
    public func execute(actionID: String, parameters: [String: AnyCodable] = [:]) async throws {
        SDKLogStore.shared.log("Executing action: \(actionID)", source: "SDKExecutionKernel", level: .info)

        let context = SDKExecutionContext(
            projectID: SDKProjectManager.shared.currentProject?.id ?? UUID(),
            parameters: parameters
        )

        // Dynamic routing based on actionID
        switch actionID {
        case let id where id.contains("note"):
            let title = parameters["title"]?.value as? String ?? "Untitled"
            let content = parameters["content"]?.value as? String ?? ""
            try await execute(action: .createNote(title: title, content: content), context: context)
        case let id where id.contains("task"):
            let title = parameters["title"]?.value as? String ?? "Untitled"
            try await execute(action: .createTask(title: title, dueDate: nil), context: context)
        case let id where id.contains("workflow"):
            if let workflowID = parameters["id"]?.value as? UUID {
                try await execute(action: .executeWorkflow(id: workflowID), context: context)
            }
        default:
            SDKLogStore.shared.log("Action \(actionID) routed to generic execution", source: "SDKExecutionKernel", level: .info)
        }
    }
}
