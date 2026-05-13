import Foundation
import Combine

@MainActor
public final class SDKWorkflowEngine: ObservableObject {
    public static let shared = SDKWorkflowEngine()

    @Published public private(set) var workflows: [SDKWorkflow] = []
    @Published public private(set) var runningWorkflows: [UUID: WorkflowExecution] = [:]
    @Published public private(set) var executionHistory: [WorkflowExecution] = []

    private init() {}

    // MARK: - Workflow CRUD

    public func createWorkflow(name: String, description: String = "", steps: [WorkflowStep] = []) -> SDKWorkflow {
        let workflow = SDKWorkflow(name: name, description: description, steps: steps)
        workflows.append(workflow)
        SDKEventBus.shared.publish(SDKBusEvent(channel: "sdk.workflow", name: "workflow.created", data: ["id": workflow.id.uuidString, "name": name]))
        return workflow
    }

    public func deleteWorkflow(id: UUID) {
        workflows.removeAll { $0.id == id }
    }

    public func updateWorkflow(id: UUID, name: String? = nil, description: String? = nil, steps: [WorkflowStep]? = nil) {
        guard let index = workflows.firstIndex(where: { $0.id == id }) else { return }
        var workflow = workflows[index]
        if let name { workflow.name = name }
        if let description { workflow.description = description }
        if let steps { workflow.steps = steps }
        workflow.updatedAt = Date()
        workflows[index] = workflow
    }

    // MARK: - Execution

    public func execute(workflowID: UUID) async throws {
        guard let workflow = workflows.first(where: { $0.id == workflowID }) else {
            throw WorkflowError.notFound
        }
        let execution = WorkflowExecution(workflowID: workflowID, workflowName: workflow.name)
        runningWorkflows[workflowID] = execution

        defer {
            runningWorkflows.removeValue(forKey: workflowID)
            executionHistory.append(execution)
        }

        for (index, step) in workflow.steps.enumerated() {
            runningWorkflows[workflowID]?.currentStepIndex = index
            runningWorkflows[workflowID]?.status = .running

            do {
                var execution = runningWorkflows[workflowID]!
                try await executeStep(step, context: &execution)
                runningWorkflows[workflowID] = execution
                runningWorkflows[workflowID]?.completedSteps.append(step.id)
            } catch {
                runningWorkflows[workflowID]?.status = .failed
                runningWorkflows[workflowID]?.error = error.localizedDescription
                SDKEventBus.shared.publish(SDKBusEvent(channel: "sdk.workflow", name: "workflow.failed", data: ["id": workflowID.uuidString, "step": step.name, "error": error.localizedDescription]))
                throw WorkflowError.stepFailed(step: step.name, underlying: error)
            }
        }
        runningWorkflows[workflowID]?.status = .completed
        runningWorkflows[workflowID]?.completedAt = Date()
        SDKEventBus.shared.publish(SDKBusEvent(channel: "sdk.workflow", name: "workflow.completed", data: ["id": workflowID.uuidString]))
    }

    public func cancelWorkflow(id: UUID) {
        runningWorkflows[id]?.status = .cancelled
        runningWorkflows.removeValue(forKey: id)
    }

    // MARK: - Private

    private func executeStep(_ step: WorkflowStep, context: inout WorkflowExecution) async throws {
        switch step.action {
        case .delay(let seconds):
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        case .publishEvent(let channel, let name, let data):
            SDKEventBus.shared.publish(SDKBusEvent(channel: channel, name: name, data: data))
        case .condition(let key, let expected):
            guard context.variables[key] == expected else {
                throw WorkflowError.conditionNotMet(key: key, expected: expected)
            }
        case .setVariable(let key, let value):
            context.variables[key] = value
        case .log(let message):
            context.logs.append(WorkflowLog(step: step.name, message: message))
        case .apiCall(let path, let method):
            let request = SDKRequest(path: path, method: method == "POST" ? .post : .get, parameters: [:])
            _ = try await SDKRouter.shared.handle(request)
        }
    }
}

// MARK: - Models

public struct SDKWorkflow: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var description: String
    public var steps: [WorkflowStep]
    public let createdAt: Date
    public var updatedAt: Date
    public var isEnabled: Bool

    public init(name: String, description: String = "", steps: [WorkflowStep] = []) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.steps = steps
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isEnabled = true
    }
}

public struct WorkflowStep: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let action: WorkflowAction
    public let timeoutSeconds: Double

    public init(name: String, action: WorkflowAction, timeoutSeconds: Double = 30) {
        self.id = UUID()
        self.name = name
        self.action = action
        self.timeoutSeconds = timeoutSeconds
    }
}

public enum WorkflowAction: Codable {
    case delay(seconds: Double)
    case publishEvent(channel: String, name: String, data: [String: String])
    case condition(key: String, expected: String)
    case setVariable(key: String, value: String)
    case log(message: String)
    case apiCall(path: String, method: String)
}

public struct WorkflowExecution: Identifiable, Codable {
    public let id: UUID
    public let workflowID: UUID
    public let workflowName: String
    public let startedAt: Date
    public var completedAt: Date?
    public var status: WorkflowStatus
    public var currentStepIndex: Int
    public var completedSteps: [UUID]
    public var variables: [String: String]
    public var logs: [WorkflowLog]
    public var error: String?

    public init(workflowID: UUID, workflowName: String) {
        self.id = UUID()
        self.workflowID = workflowID
        self.workflowName = workflowName
        self.startedAt = Date()
        self.status = .pending
        self.currentStepIndex = 0
        self.completedSteps = []
        self.variables = [:]
        self.logs = []
    }
}

public enum WorkflowStatus: String, Codable, CaseIterable, Sendable {
    case pending, running, completed, failed, cancelled
}

public struct WorkflowLog: Identifiable, Codable {
    public let id: UUID
    public let step: String
    public let message: String
    public let timestamp: Date

    public init(step: String, message: String) {
        self.id = UUID()
        self.step = step
        self.message = message
        self.timestamp = Date()
    }
}

public enum WorkflowError: LocalizedError {
    case notFound
    case stepFailed(step: String, underlying: Error)
    case conditionNotMet(key: String, expected: String)

    public var errorDescription: String? {
        switch self {
        case .notFound: return "Workflow not found"
        case .stepFailed(let step, let error): return "Step '\(step)' failed: \(error.localizedDescription)"
        case .conditionNotMet(let key, let expected): return "Condition not met: \(key) != \(expected)"
        }
    }
}
