import Foundation

struct WorkspaceTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var dueDate: Date?
    var priority: TaskPriority
    var categoryID: UUID?
    var completed: Bool
    var createdAt: Date = Date()
    var boardStatus: BoardStatus

    enum TaskPriority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case urgent = "Urgent"

        var color: String {
            switch self {
            case .low: return "6B7280"
            case .medium: return "3B82F6"
            case .high: return "F59E0B"
            case .urgent: return "EF4444"
            }
        }

        var icon: String {
            switch self {
            case .low: return "arrow.down.circle"
            case .medium: return "minus.circle"
            case .high: return "arrow.up.circle"
            case .urgent: return "exclamationmark.circle.fill"
            }
        }
    }

    enum BoardStatus: String, Codable, CaseIterable {
        case todo = "To Do"
        case inProgress = "In Progress"
        case done = "Done"
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        dueDate: Date? = nil,
        priority: TaskPriority = .medium,
        categoryID: UUID? = nil,
        completed: Bool = false,
        createdAt: Date = Date(),
        boardStatus: BoardStatus = .todo
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.priority = priority
        self.categoryID = categoryID
        self.completed = completed
        self.createdAt = createdAt
        self.boardStatus = boardStatus
    }

    var isOverdue: Bool {
        guard let due = dueDate, !completed else { return false }
        return due < Date()
    }

    var isDueToday: Bool {
        guard let due = dueDate else { return false }
        return Calendar.current.isDateInToday(due)
    }
}
