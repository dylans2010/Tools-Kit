import Foundation

/// Core workflow engine that manages multi-step, branching automation pipelines.
actor WorkflowAutomationEngine {
    static let shared = WorkflowAutomationEngine()
    private let aiService = AIService.shared
    private var activeWorkflows: [UUID: WorkflowState] = [:]

    private init() {}

    /// Compiles an email thread into a structured workflow.
    func compileThreadToWorkflow(thread: MailThread) async throws -> WorkflowState {
        let content = thread.messages.map { $0.body }.joined(separator: "\n")
        let prompt = "Convert this email thread into a multi-step execution workflow plan."
        let schema = """
        {
          "type": "object",
          "required": ["name", "steps"],
          "properties": {
            "name": { "type": "string" },
            "steps": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["title", "description", "actionType"],
                "properties": {
                  "title": { "type": "string" },
                  "description": { "type": "string" },
                  "actionType": { "type": "string" }
                }
              }
            }
          }
        }
        """
        let json = try await aiService.generateStructuredJSON(prompt: prompt + "\n\nContent:\n" + content, jsonSchema: schema)

        struct WorkflowResponse: Codable, Sendable {
            let name: String
            let steps: [StepResponse]
            struct StepResponse: Codable, Sendable {
                let title: String
                let description: String
                let actionType: String
            }
        }

        let decoded = try JSONDecoder().decode(WorkflowResponse.self, from: Data(json.utf8))
        let steps = decoded.steps.map {
            MailWorkflowStep(id: UUID(), title: $0.title, description: $0.description, actionType: $0.actionType, isCompleted: false)
        }

        let state = WorkflowState(id: UUID(), name: decoded.name, steps: steps, currentStepIndex: 0, status: .pending, threadID: thread.id)
        activeWorkflows[state.id] = state
        return state
    }

    /// Executes the next step in a workflow.
    func executeNextStep(workflowID: UUID) async throws {
        guard var workflow = activeWorkflows[workflowID], workflow.currentStepIndex < workflow.steps.count else { return }

        workflow.status = .active
        let step = workflow.steps[workflow.currentStepIndex]

        WorkspaceLogger.general.info("Executing workflow step: \(step.title)")

        switch step.actionType.lowercased() {
        case "calendar":
            let allThreads = MailStorageService.shared.loadThreads(for: "all")
            let thread = allThreads.first(where: { $0.id == workflow.threadID }) ?? MailThread(id: workflow.threadID, subject: workflow.name, messages: [], lastMessageDate: Date())
            _ = try await ExecutionBridge.shared.convertThreadToCalendarEvent(thread: thread)
        case "task":
            _ = try await ExecutionBridge.shared.createTask(title: step.title, description: step.description)
        case "reply":
            let allThreads = MailStorageService.shared.loadThreads(for: "all")
            if let thread = allThreads.first(where: { $0.id == workflow.threadID }), let lastMsg = thread.messages.last {
                _ = try await MailAIService.shared.generateReply(for: lastMsg, context: "Automated workflow reply: \(step.description)")
            }
        default:
            WorkspaceLogger.general.info("Executing manual/custom action: \(step.title)")
        }

        workflow.steps[workflow.currentStepIndex].isCompleted = true
        workflow.currentStepIndex += 1

        if workflow.currentStepIndex >= workflow.steps.count {
            workflow.status = .completed
        }

        activeWorkflows[workflowID] = workflow
    }

    func getWorkflow(id: UUID) -> WorkflowState? {
        activeWorkflows[id]
    }

    func getAllWorkflows() -> [WorkflowState] {
        Array(activeWorkflows.values)
    }
}
