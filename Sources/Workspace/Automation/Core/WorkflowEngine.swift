import Foundation
import Combine

/// Executes multi-step automations across the workspace.
final class WorkflowEngine: ObservableObject {
    static let shared = WorkflowEngine()

    @Published private(set) var workflows: [Workflow] = []
    @Published private(set) var activeRuns: [WorkflowRun] = []

    private let storageFile = "workspace_workflows.json"
    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadWorkflows()
        setupEventSubscription()
    }

    private func setupEventSubscription() {
        PluginEventBus.shared.events
            .sink { [weak self] event in
                self?.handleEvent(event)
            }
            .store(in: &cancellables)
    }

    private func handleEvent(_ event: PluginEvent) {
        let matchingWorkflows = workflows.filter {
            $0.isEnabled && $0.trigger.type == "event" && $0.trigger.actionType == event.type.rawValue
        }

        for workflow in matchingWorkflows {
            executeWorkflow(workflow, context: event.payload)
        }
    }

    func executeWorkflow(_ workflow: Workflow, context: [String: String]) {
        let run = WorkflowRun(id: UUID(), workflowID: workflow.id, timestamp: Date(), status: .running, logs: ["Starting workflow: \(workflow.name)"])
        activeRuns.insert(run, at: 0)

        Task {
            var currentLogs = run.logs
            var status: WorkflowRun.RunStatus = .success

            for step in workflow.steps {
                currentLogs.append("Executing step: \(step.actionType)")
                // Simulated step execution
                try? await Task.sleep(nanoseconds: 500 * 1_000_000)
            }

            currentLogs.append("Workflow completed successfully.")

            await MainActor.run {
                if let index = self.activeRuns.firstIndex(where: { $0.id == run.id }) {
                    self.activeRuns[index] = WorkflowRun(id: run.id, workflowID: run.workflowID, timestamp: run.timestamp, status: status, logs: currentLogs)
                }

                if let wIndex = self.workflows.firstIndex(where: { $0.id == workflow.id }) {
                    self.workflows[wIndex].lastRunAt = Date()
                }
                saveWorkflows()
            }
        }
    }

    private func loadWorkflows() {
        if WorkspacePersistence.shared.exists(filename: storageFile) {
            workflows = (try? WorkspacePersistence.shared.load([Workflow].self, from: storageFile)) ?? []
        } else {
            seedDefaultWorkflows()
        }
    }

    private func saveWorkflows() {
        try? WorkspacePersistence.shared.save(workflows, to: storageFile)
    }

    private func seedDefaultWorkflows() {
        workflows = [
            Workflow(
                id: UUID(),
                name: "Auto-Summarize & Mail",
                description: "Summarizes new notes and sends them to your inbox.",
                trigger: WorkflowTrigger(type: "event", actionType: "note.created"),
                steps: [
                    WorkflowStep(id: UUID(), actionType: "ai.summarize", config: [:]),
                    WorkflowStep(id: UUID(), actionType: "mail.send", config: ["to": "me@example.com"])
                ],
                isEnabled: true
            )
        ]
        saveWorkflows()
    }
}
