import SwiftUI

public enum FeedbackStatus: String, CaseIterable, Identifiable, Codable, Comparable {
    case draft, submitted, triaged, inProgress, resolved, closed

    public var id: String { rawValue }

    private var sortOrder: Int {
        switch self {
        case .draft: return 0
        case .submitted: return 1
        case .triaged: return 2
        case .inProgress: return 3
        case .resolved: return 4
        case .closed: return 5
        }
    }

    public static func < (lhs: FeedbackStatus, rhs: FeedbackStatus) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    public var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .submitted: return "Submitted"
        case .triaged: return "Triaged"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        case .closed: return "Closed"
        }
    }

    public var color: Color {
        switch self {
        case .draft: return .gray
        case .submitted: return .blue
        case .triaged: return .purple
        case .inProgress: return .orange
        case .resolved: return .green
        case .closed: return .secondary
        }
    }
}
