import Foundation
import Combine

/// In-memory local notification service for workspace alerts.
final class WorkspaceNotificationService: ObservableObject {
    static let shared = WorkspaceNotificationService()

    struct WorkspaceNotification: Identifiable, Sendable {
        let id: UUID
        let title: String
        let body: String
        let timestamp: Date
        var isRead: Bool
        var category: NotificationCategory
    }

    enum NotificationCategory: String, CaseIterable, Sendable {
        case deadline = "Deadline"
        case inactivity = "Inactivity"
        case update = "Update"
        case automation = "Automation"
        case alert = "Alert"
    }

    @Published private(set) var notifications: [WorkspaceNotification] = []
    @Published var unreadCount: Int = 0

    private init() {}

    func post(title: String, body: String, category: NotificationCategory = .alert) {
        let n = WorkspaceNotification(
            id: UUID(),
            title: title,
            body: body,
            timestamp: Date(),
            isRead: false,
            category: category
        )
        notifications.insert(n, at: 0)
        if notifications.count > 100 { notifications = Array(notifications.prefix(100)) }
        unreadCount = notifications.filter { !$0.isRead }.count
    }

    func markAllRead() {
        for i in notifications.indices { notifications[i].isRead = true }
        unreadCount = 0
    }

    func markRead(id: UUID) {
        guard let i = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[i].isRead = true
        unreadCount = notifications.filter { !$0.isRead }.count
    }

    func delete(id: UUID) {
        notifications.removeAll { $0.id == id }
        unreadCount = notifications.filter { !$0.isRead }.count
    }
}

/// Indexed global search across all workspace objects.
final class GlobalSearchService: ObservableObject {
    static let shared = GlobalSearchService()

    struct SearchResult: Identifiable, Sendable {
        let id = UUID()
        let title: String
        let subtitle: String
        let type: String
        let icon: String
        let relevance: Double
        let objectID: UUID?
    }

    @Published private(set) var results: [SearchResult] = []
    @Published var isSearching: Bool = false

    private init() {}

    func search(query: String, types: Set<String> = []) {
        guard !query.isEmpty else { results = []; return }
        isSearching = true

        var found: [SearchResult] = []
        let q = query.lowercased()

        // Search spaces
        for space in CollaborationManager.shared.spaces {
            var relevance = 0.0
            if space.name.lowercased().hasPrefix(q) { relevance += 3.0 }
            else if space.name.lowercased().contains(q) { relevance += 2.0 }
            if space.description.lowercased().contains(q) { relevance += 1.0 }
            if relevance > 0 && (types.isEmpty || types.contains("Space")) {
                found.append(SearchResult(title: space.name, subtitle: space.description, type: "Space", icon: space.icon, relevance: relevance, objectID: space.id))
            }
        }

        // Search tasks
        for task in ProjectExecutionBoardTool.shared.tasks {
            var relevance = 0.0
            if task.title.lowercased().hasPrefix(q) { relevance += 3.0 }
            else if task.title.lowercased().contains(q) { relevance += 2.0 }
            if relevance > 0 && (types.isEmpty || types.contains("Task")) {
                found.append(SearchResult(title: task.title, subtitle: "Task · \(task.status.rawValue)", type: "Task", icon: "checkmark.square", relevance: relevance, objectID: task.id))
            }
        }

        // Search decisions
        for decision in DecisionEngineTool.shared.decisions {
            var relevance = 0.0
            if decision.title.lowercased().hasPrefix(q) { relevance += 3.0 }
            else if decision.title.lowercased().contains(q) { relevance += 2.0 }
            if relevance > 0 && (types.isEmpty || types.contains("Decision")) {
                found.append(SearchResult(title: decision.title, subtitle: "Decision · \(decision.options.count) options", type: "Decision", icon: "chart.bar", relevance: relevance, objectID: decision.id))
            }
        }

        // Search content graph nodes
        for node in ContentGraphService.shared.nodes {
            var relevance = 0.0
            if node.label.lowercased().hasPrefix(q) { relevance += 3.0 }
            else if node.label.lowercased().contains(q) { relevance += 2.0 }
            if node.tags.contains(where: { $0.lowercased().contains(q) }) { relevance += 1.0 }
            if relevance > 0 && (types.isEmpty || types.contains(node.nodeType.rawValue)) {
                found.append(SearchResult(title: node.label, subtitle: node.nodeType.rawValue, type: node.nodeType.rawValue, icon: iconFor(type: node.nodeType), relevance: relevance, objectID: node.id))
            }
        }

        results = found.sorted { $0.relevance > $1.relevance }
        isSearching = false
    }

    private func iconFor(type: ContentGraphService.NodeType) -> String {
        switch type {
        case .note: return "note.text"
        case .task: return "checkmark.square"
        case .file: return "doc"
        case .decision: return "chart.bar"
        case .member: return "person"
        }
    }
}

/// Detects and repairs workspace data integrity issues.
final class DataIntegrityService: ObservableObject {
    static let shared = DataIntegrityService()

    struct IntegrityIssue: Identifiable, Sendable {
        let id = UUID()
        let severity: Severity
        let description: String
        let autoFixable: Bool
        var isFixed: Bool = false
    }

    enum Severity: String, CaseIterable, Sendable {
        case info = "Info"
        case warning = "Warning"
        case error = "Error"
    }

    @Published private(set) var issues: [IntegrityIssue] = []
    @Published var isScanning: Bool = false

    private init() {}

    func runScan() {
        isScanning = true
        var found: [IntegrityIssue] = []

        // Check for spaces with empty names
        let emptyNameSpaces = CollaborationManager.shared.spaces.filter { $0.name.isEmpty }
        if !emptyNameSpaces.isEmpty {
            found.append(IntegrityIssue(severity: .error, description: "\(emptyNameSpaces.count) space(s) have empty names", autoFixable: false))
        }

        // Check for tasks with no title
        let emptyTasks = ProjectExecutionBoardTool.shared.tasks.filter { $0.title.isEmpty }
        if !emptyTasks.isEmpty {
            found.append(IntegrityIssue(severity: .warning, description: "\(emptyTasks.count) task(s) have empty titles", autoFixable: true))
        }

        // Check for decisions with no options
        let emptyDecisions = DecisionEngineTool.shared.decisions.filter { $0.options.isEmpty }
        if !emptyDecisions.isEmpty {
            found.append(IntegrityIssue(severity: .info, description: "\(emptyDecisions.count) decision(s) have no options", autoFixable: false))
        }

        // Check orphaned task IDs
        let allTaskIDs = Set(ProjectExecutionBoardTool.shared.tasks.map { $0.id })
        let referencedTaskIDs = Set(CollaborationManager.shared.spaces.flatMap { $0.taskIDs })
        let orphanedRefs = referencedTaskIDs.subtracting(allTaskIDs)
        if !orphanedRefs.isEmpty {
            found.append(IntegrityIssue(severity: .warning, description: "\(orphanedRefs.count) orphaned task reference(s) in spaces", autoFixable: true))
        }

        // Check automations with no actions
        let emptyAutomations = WorkspaceAutomationEngine.shared.automations.filter { $0.actions.isEmpty }
        if !emptyAutomations.isEmpty {
            found.append(IntegrityIssue(severity: .info, description: "\(emptyAutomations.count) automation(s) have no actions defined", autoFixable: false))
        }

        if found.isEmpty {
            found.append(IntegrityIssue(severity: .info, description: "No integrity issues found. Workspace is healthy.", autoFixable: false))
        }

        issues = found
        isScanning = false
    }

    func autoFix(issue: IntegrityIssue) {
        guard issue.autoFixable else { return }
        guard let index = issues.firstIndex(where: { $0.id == issue.id }) else { return }

        // Remove empty-titled tasks
        let emptyTaskIDs = ProjectExecutionBoardTool.shared.tasks.filter { $0.title.isEmpty }.map { $0.id }
        ProjectExecutionBoardTool.shared.removeTasks(ids: emptyTaskIDs)

        // Clean orphaned task refs from spaces
        CollaborationManager.shared.cleanOrphanedTaskRefs()

        issues[index].isFixed = true
    }
}

// MARK: - Helpers

extension ProjectExecutionBoardTool {
    func removeTasks(ids: [UUID]) {
        tasks.removeAll { ids.contains($0.id) }
        try? WorkspacePersistence.shared.save(tasks, to: "collaboration_tasks.json")
    }
}

extension CollaborationManager {
    func cleanOrphanedTaskRefs() {
        let allTaskIDs = Set(ProjectExecutionBoardTool.shared.tasks.map { $0.id })
        for i in spaces.indices {
            spaces[i].taskIDs = spaces[i].taskIDs.filter { allTaskIDs.contains($0) }
        }
        saveData()
    }
}
