import Foundation
import Combine

final class WorkflowRunner {
    static let shared = WorkflowRunner()

    private let eventBus = PluginEventBus.shared
    private let dataStore = UnifiedDataStore.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupEventSubscription()
    }

    private func setupEventSubscription() {
        eventBus.subscribe { [weak self] event in
            self?.handleEvent(event)
        }
        .store(in: &cancellables)
    }

    private func handleEvent(_ event: PluginEvent) {
        let workflows = dataStore.loadWorkflows().filter { $0.isEnabled }

        for workflow in workflows {
            if workflow.trigger.capability == event.capability.rawValue &&
               workflow.trigger.action == event.action {
                executeWorkflow(workflow, triggerEvent: event)
            }
        }
    }

    private func executeWorkflow(_ workflow: WorkspaceWorkflow, triggerEvent: PluginEvent) {
        print("[WorkflowRunner] Executing workflow: \(workflow.title)")

        for action in workflow.actions {
            executeAction(action, context: triggerEvent.payload)
        }
    }

    private func executeAction(_ action: WorkspaceWorkflow.WorkflowAction, context: [String: String]) {
        switch action.type {
        case "create_task":
            let title = action.parameters["title"] ?? "Automated Task"
            let task = WorkspaceTask(title: title, description: "Created by workflow")
            TasksManager.shared.addTask(task)
        case "send_notification":
            let message = action.parameters["message"] ?? "Notification"
            print("[WorkflowRunner] Notification: \(message)")
        default:
            break
        }
    }
}
