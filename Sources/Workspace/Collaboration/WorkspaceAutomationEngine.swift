import Foundation
import Combine

/// Trigger → Condition → Action automation engine for collaboration workspaces.
final class WorkspaceAutomationEngine: ObservableObject {
    static let shared = WorkspaceAutomationEngine()

    // MARK: - Models

    enum TriggerType: String, Codable, CaseIterable, Sendable {
        case taskOverdue = "Task Overdue"
        case fileUpdated = "File Updated"
        case workspaceInactive = "Workspace Inactive"
        case commitCreated = "Commit Created"
        case memberJoined = "Member Joined"
        case spaceCreated = "Space Created"
    }

    enum ConditionOperator: String, Codable, CaseIterable, Sendable {
        case always = "Always"
        case contains = "Contains"
        case equals = "Equals"
        case greaterThan = "Greater Than"
    }

    struct AutomationCondition: Codable, Identifiable, Sendable {
        let id: UUID
        var field: String
        var conditionOperator: ConditionOperator
        var value: String
    }

    enum ActionType: String, Codable, CaseIterable, Sendable {
        case increasePriority = "Increase Priority"
        case logActivity = "Log Activity"
        case sendNotification = "Send Notification"
        case generateReport = "Generate Report"
        case assignMember = "Assign Member"
        case updateStatus = "Update Status"
    }

    struct AutomationAction: Codable, Identifiable, Sendable {
        let id: UUID
        var actionType: ActionType
        var parameters: [String: String]
    }

    struct Automation: Codable, Identifiable, Sendable {
        let id: UUID
        var name: String
        var triggerType: TriggerType
        var conditions: [AutomationCondition]
        var actions: [AutomationAction]
        var isEnabled: Bool
        var executionCount: Int
        var lastExecuted: Date?
        var createdAt: Date
    }

    // MARK: - State

    @Published private(set) var automations: [Automation] = []
    @Published private(set) var executionLog: [String] = []

    private let storageFile = "workspace_automations.json"

    private init() {
        loadData()
    }

    // MARK: - CRUD

    func createAutomation(
        name: String,
        trigger: TriggerType,
        conditions: [AutomationCondition] = [],
        actions: [AutomationAction] = []
    ) -> Automation {
        let automation = Automation(
            id: UUID(),
            name: name,
            triggerType: trigger,
            conditions: conditions,
            actions: actions,
            isEnabled: true,
            executionCount: 0,
            lastExecuted: nil,
            createdAt: Date()
        )
        automations.append(automation)
        saveData()
        return automation
    }

    func toggleAutomation(id: UUID) {
        guard let index = automations.firstIndex(where: { $0.id == id }) else { return }
        automations[index].isEnabled.toggle()
        saveData()
    }

    func deleteAutomation(id: UUID) {
        automations.removeAll { $0.id == id }
        saveData()
    }

    func updateAutomation(_ updated: Automation) {
        guard let index = automations.firstIndex(where: { $0.id == updated.id }) else { return }
        automations[index] = updated
        saveData()
    }

    // MARK: - Execution

    /// Fire all enabled automations that match the given trigger.
    func fire(trigger: TriggerType, context: [String: String] = [:]) {
        let candidates = automations.filter { $0.isEnabled && $0.triggerType == trigger }
        for automation in candidates {
            guard evaluateConditions(automation.conditions, context: context) else { continue }
            execute(automation: automation, context: context)
        }
    }

    private func evaluateConditions(_ conditions: [AutomationCondition], context: [String: String]) -> Bool {
        guard !conditions.isEmpty else { return true }
        return conditions.allSatisfy { condition in
            let fieldValue = context[condition.field] ?? ""
            switch condition.conditionOperator {
            case .always: return true
            case .contains: return fieldValue.localizedCaseInsensitiveContains(condition.value)
            case .equals: return fieldValue == condition.value
            case .greaterThan:
                guard let lhs = Double(fieldValue), let rhs = Double(condition.value) else { return false }
                return lhs > rhs
            }
        }
    }

    private func execute(automation: Automation, context: [String: String]) {
        guard let index = automations.firstIndex(where: { $0.id == automation.id }) else { return }
        automations[index].executionCount += 1
        automations[index].lastExecuted = Date()

        for action in automation.actions {
            let result = performAction(action, context: context)
            let logEntry = "[\(Date().formatted(date: .abbreviated, time: .shortened))] '\(automation.name)' → \(action.actionType.rawValue): \(result)"
            executionLog.insert(logEntry, at: 0)
            if executionLog.count > 200 { executionLog = Array(executionLog.prefix(200)) }
        }
        saveData()
    }

    private func performAction(_ action: AutomationAction, context: [String: String]) -> String {
        switch action.actionType {
        case .increasePriority:
            return "Priority increased for \(context["taskTitle"] ?? "task")"
        case .logActivity:
            let message = action.parameters["message"] ?? "Automation triggered"
            if let spaceIDString = context["spaceID"], let spaceID = UUID(uuidString: spaceIDString) {
                CollaborationManager.shared.logAutomationActivity(spaceID: spaceID, message: message)
            }
            return "Logged: \(message)"
        case .sendNotification:
            let title = action.parameters["title"] ?? "Workspace Alert"
            WorkspaceNotificationService.shared.post(title: title, body: action.parameters["body"] ?? "")
            return "Notification sent: \(title)"
        case .generateReport:
            return "Report generation queued"
        case .assignMember:
            return "Assigned to \(action.parameters["member"] ?? "member")"
        case .updateStatus:
            return "Status updated to \(action.parameters["status"] ?? "updated")"
        }
    }

    // MARK: - Persistence

    private func saveData() {
        let snapshot = automations
        DispatchQueue.global(qos: .utility).async {
            try? WorkspacePersistence.shared.save(snapshot, to: self.storageFile)
        }
    }

    private func loadData() {
        if WorkspacePersistence.shared.exists(filename: storageFile) {
            automations = (try? WorkspacePersistence.shared.load([Automation].self, from: storageFile)) ?? []
        }
    }
}

// Extend CollaborationManager to expose a logging helper for automation
extension CollaborationManager {
    func logAutomationActivity(spaceID: UUID, message: String) {
        guard let index = spaces.firstIndex(where: { $0.id == spaceID }) else { return }
        let log = ActivityLog(
            id: UUID(),
            timestamp: Date(),
            userID: UUID(),
            userName: "Automation",
            action: "🤖 Automation: \(message)",
            objectID: nil,
            objectType: nil
        )
        spaces[index].activityFeed.insert(log, at: 0)
        saveData()
    }
}
