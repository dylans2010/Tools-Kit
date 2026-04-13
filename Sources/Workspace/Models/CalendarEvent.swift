import Foundation

struct CalendarEvent: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var date: Date
    var startTime: Date
    var endTime: Date
    var location: String
    var priority: EventPriority
    var createdAt: Date = Date()

    enum EventPriority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"

        var colorHex: String {
            switch self {
            case .low: return "6B7280"
            case .medium: return "3B82F6"
            case .high: return "EF4444"
            }
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        date: Date = Date(),
        startTime: Date = Date(),
        endTime: Date = Date().addingTimeInterval(3600),
        location: String = "",
        priority: EventPriority = .medium,
        createdAt: Date = Date()
    ) {
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

    var durationMinutes: Int {
        let diff = endTime.timeIntervalSince(startTime)
        return max(0, Int(diff / 60))
    }

    var formattedTimeRange: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return "\(f.string(from: startTime)) – \(f.string(from: endTime))"
    }
}
