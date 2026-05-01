import Foundation

/// Represents a task on the execution board.
struct BoardTask: Identifiable, Codable {
    let id: UUID
    var title: String
    var status: BoardColumn
    var assigneeID: UUID?
    var dependencies: [UUID] = [] // IDs of other tasks
}

enum BoardColumn: String, Codable, CaseIterable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case review = "Review"
    case done = "Done"
}

/// Manages the project execution board for a space.
final class ExecutionBoardManager: ObservableObject {
    static let shared = ExecutionBoardManager()

    @Published var tasksBySpace: [UUID: [BoardTask]] = [:]

    private init() {}

    func addTask(spaceID: UUID, title: String) {
        let task = BoardTask(id: UUID(), title: title, status: .todo)
        var current = tasksBySpace[spaceID] ?? []
        current.append(task)
        tasksBySpace[spaceID] = current
    }

    func moveTask(spaceID: UUID, taskID: UUID, to status: BoardColumn) {
        if let index = tasksBySpace[spaceID]?.firstIndex(where: { $0.id == taskID }) {
            tasksBySpace[spaceID]?[index].status = status
        }
    }
}
