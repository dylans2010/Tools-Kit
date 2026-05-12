import Foundation
import Combine

/// Specialized tool for group decision making and weighted voting.
final class DecisionEngineTool: ObservableObject {
    struct DecisionOption: Identifiable, Codable, Sendable {
        let id: UUID
        var title: String
        var votes: Int
        var weight: Double
    }

    struct Decision: Identifiable, Codable, Sendable {
        let id: UUID
        var title: String
        var options: [DecisionOption]
    }

    @Published var decisions: [Decision] = []
    private let decisionsFile = "collaboration_decisions.json"

    static let shared = DecisionEngineTool()

    private init() {
        loadDecisions()
    }

    func createDecision(spaceID: UUID, title: String) -> Decision {
        let decision = Decision(id: UUID(), title: title, options: [])
        decisions.append(decision)

        if let index = CollaborationManager.shared.spaces.firstIndex(where: { $0.id == spaceID }) {
            CollaborationManager.shared.spaces[index].decisionIDs.append(decision.id)
            CollaborationManager.shared.saveData()
        }

        saveDecisions()
        return decision
    }

    func addOption(to decisionID: UUID, title: String) {
        if let index = decisions.firstIndex(where: { $0.id == decisionID }) {
            decisions[index].options.append(DecisionOption(id: UUID(), title: title, votes: 0, weight: 1.0))
            saveDecisions()
        }
    }

    func vote(decisionID: UUID, optionID: UUID) {
        if let dIndex = decisions.firstIndex(where: { $0.id == decisionID }),
           let oIndex = decisions[dIndex].options.firstIndex(where: { $0.id == optionID }) {
            decisions[dIndex].options[oIndex].votes += 1
            saveDecisions()
        }
    }

    private func saveDecisions() {
        try? WorkspacePersistence.shared.save(decisions, to: decisionsFile)
    }

    private func loadDecisions() {
        if WorkspacePersistence.shared.exists(filename: decisionsFile) {
            decisions = (try? WorkspacePersistence.shared.load([Decision].self, from: decisionsFile)) ?? []
        }
    }
}

/// Project board with dependency tracking and Kanban-style execution.
final class ProjectExecutionBoardTool: ObservableObject {
    enum TaskStatus: String, Codable, Sendable {
        case todo, inProgress, blocked, done
    }

    struct BoardTask: Identifiable, Codable, Sendable {
        let id: UUID
        var title: String
        var status: TaskStatus
        var dependencyIDs: [UUID]
    }

    @Published var tasks: [BoardTask] = []
    private let tasksFile = "collaboration_tasks.json"

    static let shared = ProjectExecutionBoardTool()

    private init() {
        loadTasks()
    }

    func addTask(spaceID: UUID, title: String) {
        let task = BoardTask(id: UUID(), title: title, status: .todo, dependencyIDs: [])
        tasks.append(task)

        if let index = CollaborationManager.shared.spaces.firstIndex(where: { $0.id == spaceID }) {
            CollaborationManager.shared.spaces[index].taskIDs.append(task.id)
            CollaborationManager.shared.saveData()
        }

        saveTasks()
    }

    func updateTaskStatus(taskID: UUID, status: TaskStatus) {
        if let index = tasks.firstIndex(where: { $0.id == taskID }) {
            tasks[index].status = status
            saveTasks()
        }
    }

    private func saveTasks() {
        try? WorkspacePersistence.shared.save(tasks, to: tasksFile)
    }

    private func loadTasks() {
        if WorkspacePersistence.shared.exists(filename: tasksFile) {
            tasks = (try? WorkspacePersistence.shared.load([BoardTask].self, from: tasksFile)) ?? []
        }
    }
}

/// Interactive graph of workspace object relationships.
final class KnowledgeGraphTool: ObservableObject {
    struct GraphNode: Identifiable, Sendable {
        let id: UUID
        let label: String
        let type: String
    }

    struct GraphEdge: Identifiable, Sendable {
        let id: UUID
        let sourceID: UUID
        let targetID: UUID
    }

    @Published var nodes: [GraphNode] = []
    @Published var edges: [GraphEdge] = []

    func buildGraph(for spaceID: UUID) {
        guard let space = CollaborationManager.shared.spaces.first(where: { $0.id == spaceID }) else { return }

        nodes = []
        edges = []

        // Add space node
        nodes.append(GraphNode(id: space.id, label: space.name, type: "Space"))

        // Add member nodes
        for member in space.members {
            let memberNode = GraphNode(id: member.id, label: member.name, type: "Member")
            nodes.append(memberNode)
            edges.append(GraphEdge(id: UUID(), sourceID: space.id, targetID: member.id))
        }

        // Add object nodes
        let objectIDs = space.notebookIDs + space.slideDeckIDs + space.mediaProjectIDs
        for id in objectIDs {
            if let type = CollaborationFramework.shared.indexedObjects[id] {
                nodes.append(GraphNode(id: id, label: "Object \(id.uuidString.prefix(4))", type: type.rawValue))
                edges.append(GraphEdge(id: UUID(), sourceID: space.id, targetID: id))
            }
        }
    }
}

/// Real-time multi-user session management.
final class LiveCollaborationStudioTool: ObservableObject {
    @Published var activeParticipants: [SpaceMember] = []

    func joinSession(spaceID: UUID, member: SpaceMember) {
        if !activeParticipants.contains(where: { $0.id == member.id }) {
            activeParticipants.append(member)
        }
    }

    func leaveSession(memberID: UUID) {
        activeParticipants.removeAll { $0.id == memberID }
    }
}

/// Workspace-wide contribution and usage analytics.
final class WorkspaceAnalyticsTool: ObservableObject {
    @Published var totalCommits: Int = 0
    @Published var activeUsersCount: Int = 0

    func fetchAnalytics(for spaceID: UUID) {
        guard let space = CollaborationManager.shared.spaces.first(where: { $0.id == spaceID }) else { return }

        // Calculate real metrics
        totalCommits = space.branches.reduce(0) { $0 + CollaborationManager.shared.getCommitHistory(branchID: $1.id).count }
        activeUsersCount = Set(space.activityFeed.map { $0.userID }).count
        if activeUsersCount == 0 && !space.activityFeed.isEmpty {
             activeUsersCount = 1 // At least the local user
        }
    }
}
