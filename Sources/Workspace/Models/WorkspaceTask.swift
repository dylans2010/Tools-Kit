import Foundation

struct WorkspaceTask: Identifiable, Codable {
    var id: UUID
    var title: String
    var description: String
    var dueDate: Date?
    var priority: TaskPriority
    var categoryID: UUID?
    var completed: Bool
    var createdAt: Date

    init(id: UUID = UUID(),
         title: String,
         description: String = "",
         dueDate: Date? = nil,
         priority: TaskPriority = .medium,
         categoryID: UUID? = nil,
         completed: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.priority = priority
        self.categoryID = categoryID
        self.completed = completed
        self.createdAt = createdAt
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

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "exclamationmark.circle"
        case .critical: return "exclamationmark.2"
        }
    }

    var color: String {
        switch self {
        case .low: return "#34C759"
        case .medium: return "#FF9500"
        case .high: return "#FF3B30"
        case .critical: return "#AF52DE"
        }
    }
}
