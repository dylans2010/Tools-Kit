import SwiftUI

public enum FeedbackStatus: String, CaseIterable, Identifiable, Codable {
    case draft, submitted, triaged, inProgress, resolved, closed

    public var id: String { rawValue }

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
