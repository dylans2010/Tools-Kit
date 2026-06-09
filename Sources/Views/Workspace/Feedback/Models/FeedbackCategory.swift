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

    public var questions: [FeedbackQuestion] {
        switch self {
        case .workspace:
            return [
                FeedbackQuestion(id: "project_count", title: "How many active projects do you have?", type: .text, placeholder: "e.g. 5", isRequired: true),
                FeedbackQuestion(id: "collaboration_usage", title: "Do you use collaboration features frequently?", type: .toggle),
                FeedbackQuestion(id: "main_tool", title: "Which workspace tool do you use most?", type: .singleChoice, options: ["Notebooks", "Spreadsheets", "Drawings", "Slides"])
            ]
        case .aiChat:
            return [
                FeedbackQuestion(id: "model_used", title: "Which AI model were you using?", type: .singleChoice, options: ["GPT-4", "Claude 3.5", "Gemini Pro", "Local"]),
                FeedbackQuestion(id: "response_speed", title: "Was the response speed satisfactory?", type: .toggle),
                FeedbackQuestion(id: "hallucination", title: "Did you notice any hallucinations?", type: .toggle),
                FeedbackQuestion(id: "input_context", title: "Describe the input context", type: .longText)
            ]
        case .performance:
            return [
                FeedbackQuestion(id: "lag_area", title: "Where did you notice lag?", type: .text, placeholder: "e.g. Navigation, Typing"),
                FeedbackQuestion(id: "duration", title: "How long has this been happening?", type: .singleChoice, options: ["Just now", "Since last update", "Always"]),
                FeedbackQuestion(id: "battery_drain", title: "Did you notice high battery drain?", type: .toggle)
            ]
        case .uiux:
            return [
                FeedbackQuestion(id: "clutter_score", title: "On a scale of 1-5, how cluttered is the UI?", type: .text, placeholder: "1 (Clean) - 5 (Cluttered)"),
                FeedbackQuestion(id: "suggestion", title: "What would you change first?", type: .longText)
            ]
        case .security:
            return [
                FeedbackQuestion(id: "leak_type", title: "Potential leak type", type: .singleChoice, options: ["Data Exposure", "Unauthorized Access", "Auth Bypass"]),
                FeedbackQuestion(id: "is_urgent", title: "Is this an urgent vulnerability?", type: .toggle, isRequired: true)
            ]
        default:
            return [
                FeedbackQuestion(id: "additional_info", title: "Any specific details for this category?", type: .longText)
            ]
        }
    }
}
