import Foundation

struct CalendarEvent: Identifiable, Codable, Sendable {
    var id: UUID
    var title: String
    var description: String
    var date: Date
    var startTime: Date
    var endTime: Date
    var location: String
    var priority: EventPriority
    var createdAt: Date

    init(id: UUID = UUID(),
         title: String,
         description: String = "",
         date: Date = Date(),
         startTime: Date = Date(),
         endTime: Date = Date().addingTimeInterval(3600),
         location: String = "",
         priority: EventPriority = .normal,
         createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.priority = priority
        self.createdAt = createdAt
    }

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "\(formatter.string(from: startTime)) – \(formatter.string(from: endTime))"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

enum EventPriority: String, Codable, CaseIterable, Sendable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"
    case critical = "Critical"

    var color: String {
        switch self {
        case .low: return "#34C759"
        case .normal: return "#007AFF"
        case .high: return "#FF9500"
        case .critical: return "#FF3B30"
        }
    }
}
