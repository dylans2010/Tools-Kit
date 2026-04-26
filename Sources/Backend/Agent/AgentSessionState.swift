import Foundation
import Combine

/// Canonical session state consumed by Agent UI views.
final class AgentSessionState: ObservableObject, Identifiable {
    let id: String
    let workspaceId: String

    @Published var selectedTab: Int = 0
    @Published var session: AgentSession?

    @Published var toolExecutions: [AgentToolExecution] = []
    @Published var memory: [String: AgentMemoryEntry] = [:]
    @Published var checkpoints: [AgentCheckpoint] = []
    @Published var diffs: [String: AgentDiff] = [:]
    @Published var timeline: [AgentTimelineStep] = []
    @Published var checklist: [AgentChecklistItem] = []
    @Published var timelineTools: [String: [AgentToolExecution]] = [:]
    @Published var workspaceFiles: [String] = []

    @Published var executionEvents: [AgentExecutionEvent] = []
    @Published var logs: [String] = []
    @Published var fileOperations: [AgentFileOperation] = []
    @Published var gitOperations: [AgentGitOperation] = []
    @Published var workflowTriggers: [AgentWorkflowTrigger] = []
    @Published var currentStep: String?
    @Published var finalOutput: String?
    @Published var debugSnapshots: [AgentDebugSnapshot] = []

    @Published var lastError: String?
    @Published var isCompleted = false

    init(sessionId: String, workspaceId: String) {
        self.id = sessionId
        self.workspaceId = workspaceId
    }

    func apply(event: AgentExecutionEvent, debugSnapshot: AgentDebugSnapshot?) {
        executionEvents.append(event)
        executionEvents.sort { $0.timestamp < $1.timestamp }

        switch event.type {
        case .sessionStarted:
            finalOutput = nil
        case .stepStarted:
            currentStep = event.title
            timeline.append(AgentTimelineStep(id: event.stepId ?? event.id, step: event.title, status: "in_progress", timestamp: event.timestamp))
        case .stepProgress:
            if let stepId = event.stepId, let index = timeline.firstIndex(where: { $0.id == stepId }) {
                let status = (event.payload["step_status"]?.value as? String) ?? "in_progress"
                timeline[index] = AgentTimelineStep(id: stepId, step: timeline[index].step, status: status, timestamp: event.timestamp)
            }
            logs.append(event.message)
        case .checklistUpdated:
            let id = (event.payload["checklist_id"]?.value as? String) ?? event.stepId ?? UUID().uuidString
            let status = (event.payload["checklist_status"]?.value as? String) ?? "in_progress"
            let details = (event.payload["checklist_details"]?.value as? String) ?? event.message
            if let index = checklist.firstIndex(where: { $0.id == id }) {
                checklist[index] = AgentChecklistItem(id: id, title: event.title, status: status, details: details, timestamp: event.timestamp)
            } else {
                checklist.append(AgentChecklistItem(id: id, title: event.title, status: status, details: details, timestamp: event.timestamp))
            }
        case .logOutput:
            logs.append("[\(event.title)] \(event.message)")
        case .fileGenerated, .fileUpdated:
            let path = (event.payload["file_path"]?.value as? String) ?? event.title
            let patch = event.payload["patch"]?.value as? String
            diffs[path] = AgentDiff(filePath: path, diff: patch ?? "")
            if !workspaceFiles.contains(path) { workspaceFiles.append(path) }
            fileOperations.append(
                AgentFileOperation(
                    id: event.id,
                    path: path,
                    operation: event.type == .fileGenerated ? .generated : .updated,
                    patch: patch,
                    content: event.payload["content"]?.value as? String,
                    timestamp: event.timestamp
                )
            )
        case .gitOperation:
            gitOperations.append(.init(id: event.id, action: event.title, status: event.message, summary: event.message, timestamp: event.timestamp))
        case .workflowTriggered:
            workflowTriggers.append(.init(id: event.id, workflowName: event.title, status: "triggered", details: event.message, timestamp: event.timestamp))
        case .sessionCompleted:
            isCompleted = true
            finalOutput = event.message
        case .sessionFailed:
            isCompleted = true
            lastError = event.message
        }

        if let debugSnapshot {
            debugSnapshots.append(debugSnapshot)
        }
    }

    struct PersistenceModel: Codable {
        let id: String
        let workspaceId: String
        let selectedTab: Int
        let session: AgentSession?
        let timeline: [AgentTimelineStep]
        let checklist: [AgentChecklistItem]
        let executionEvents: [AgentExecutionEvent]
        let logs: [String]
        let fileOperations: [AgentFileOperation]
        let gitOperations: [AgentGitOperation]
        let workflowTriggers: [AgentWorkflowTrigger]
        let currentStep: String?
        let finalOutput: String?
        let isCompleted: Bool
        let lastError: String?
    }

    var persistenceModel: PersistenceModel {
        .init(
            id: id,
            workspaceId: workspaceId,
            selectedTab: selectedTab,
            session: session,
            timeline: timeline,
            checklist: checklist,
            executionEvents: executionEvents,
            logs: logs,
            fileOperations: fileOperations,
            gitOperations: gitOperations,
            workflowTriggers: workflowTriggers,
            currentStep: currentStep,
            finalOutput: finalOutput,
            isCompleted: isCompleted,
            lastError: lastError
        )
    }

    convenience init(model: PersistenceModel) {
        self.init(sessionId: model.id, workspaceId: model.workspaceId)
        self.selectedTab = model.selectedTab
        self.session = model.session
        self.timeline = model.timeline
        self.checklist = model.checklist
        self.executionEvents = model.executionEvents
        self.logs = model.logs
        self.fileOperations = model.fileOperations
        self.gitOperations = model.gitOperations
        self.workflowTriggers = model.workflowTriggers
        self.currentStep = model.currentStep
        self.finalOutput = model.finalOutput
        self.isCompleted = model.isCompleted
        self.lastError = model.lastError

        for op in model.fileOperations {
            if let patch = op.patch {
                self.diffs[op.path] = AgentDiff(filePath: op.path, diff: patch)
            }
            if !self.workspaceFiles.contains(op.path) {
                self.workspaceFiles.append(op.path)
            }
        }
    }
}

struct AgentChecklistItem: Identifiable, Codable {
    let id: String
    let title: String
    let status: String
    let details: String
    let timestamp: Date
}
