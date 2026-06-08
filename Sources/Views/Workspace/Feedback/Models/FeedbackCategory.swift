import Foundation

public enum FeedbackCategory: String, CaseIterable, Identifiable, Codable {
    case workspace, music, toolsDashboard, workouts, aiChat, externalIntegrations, syncCloud, performance, uiux, security, other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .workspace: return "Workspace"
        case .music: return "Music"
        case .toolsDashboard: return "Tools Dashboard"
        case .workouts: return "Workouts"
        case .aiChat: return "AI Chat"
        case .externalIntegrations: return "External Integrations"
        case .syncCloud: return "Sync / Cloud"
        case .performance: return "Performance"
        case .uiux: return "UI / UX"
        case .security: return "Security"
        case .other: return "Other"
        }
    }

    public var icon: String {
        switch self {
        case .workspace: return "briefcase.fill"
        case .music: return "music.note"
        case .toolsDashboard: return "square.grid.2x2.fill"
        case .workouts: return "figure.run"
        case .aiChat: return "message.fill"
        case .externalIntegrations: return "link"
        case .syncCloud: return "icloud.fill"
        case .performance: return "gauge.medium"
        case .uiux: return "paintbrush.fill"
        case .security: return "shield.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}
