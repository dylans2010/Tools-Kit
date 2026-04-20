import Foundation

enum FeedbackCategory: String, CaseIterable, Identifiable, Codable {
    case bug
    case feature
    case general

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bug: return "Bug"
        case .feature: return "Feature Request"
        case .general: return "General"
        }
    }
}

enum FeedbackStatus: String, CaseIterable, Identifiable, Codable {
    case open
    case inProgress = "in_progress"
    case resolved
    case closed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        case .closed: return "Closed"
        }
    }
}

enum FeedbackPriority: String, CaseIterable, Identifiable, Codable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

struct Feedback: Identifiable {
    let id: String
    let userId: String?
    let userName: String
    let message: String
    let category: String
    let createdAt: Date
    let device: String
    let appVersion: String
    var status: String
    var priority: String
    var internalNotes: String
    var lastUpdatedAt: Date?
    var assignedTo: String?
    var userCanViewStatus: Bool
}

extension Feedback {
    var categoryValue: FeedbackCategory {
        FeedbackCategory(rawValue: category) ?? .general
    }

    var statusValue: FeedbackStatus {
        FeedbackStatus(rawValue: status) ?? .open
    }

    var priorityValue: FeedbackPriority {
        FeedbackPriority(rawValue: priority) ?? .medium
    }
}
