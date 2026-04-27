import Foundation

struct AgentDebugSnapshot: Codable {
    let id: UUID
    let timestamp: Date
    let state: SystemAgentState
    let history: [SystemAgentMessage]
    let stateTransition: String
    let uiTrigger: String
    let frameworkPhase: String

    init(
        state: SystemAgentState,
        history: [SystemAgentMessage],
        stateTransition: String = "",
        uiTrigger: String = "",
        frameworkPhase: String = ""
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.state = state
        self.history = history
        self.stateTransition = stateTransition
        self.uiTrigger = uiTrigger
        self.frameworkPhase = frameworkPhase
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case stateDescriptor
        case history
        case stateTransition
        case uiTrigger
        case frameworkPhase
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        let stateDescriptor = try container.decodeIfPresent(String.self, forKey: .stateDescriptor) ?? "idle"
        state = Self.state(from: stateDescriptor)
        history = try container.decode([SystemAgentMessage].self, forKey: .history)
        stateTransition = try container.decodeIfPresent(String.self, forKey: .stateTransition) ?? ""
        uiTrigger = try container.decodeIfPresent(String.self, forKey: .uiTrigger) ?? ""
        frameworkPhase = try container.decodeIfPresent(String.self, forKey: .frameworkPhase) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(Self.stateDescriptor(from: state), forKey: .stateDescriptor)
        try container.encode(history, forKey: .history)
        try container.encode(stateTransition, forKey: .stateTransition)
        try container.encode(uiTrigger, forKey: .uiTrigger)
        try container.encode(frameworkPhase, forKey: .frameworkPhase)
    }

    private static func stateDescriptor(from state: SystemAgentState) -> String {
        switch state {
        case .idle:
            return "idle"
        case .thinking:
            return "thinking"
        case .executingTool(let name):
            return "executingTool:\(name)"
        case .responding:
            return "responding"
        case .completed:
            return "completed"
        case .failed(let error):
            return "failed:\(error.localizedDescription)"
        }
    }

    private static func state(from descriptor: String) -> SystemAgentState {
        if descriptor.hasPrefix("executingTool:") {
            let toolName = String(descriptor.dropFirst("executingTool:".count))
            return .executingTool(name: toolName)
        }

        if descriptor.hasPrefix("failed:") {
            let message = String(descriptor.dropFirst("failed:".count))
            return .failed(NSError(domain: "AgentDebugSnapshot", code: 1, userInfo: [NSLocalizedDescriptionKey: message]))
        }

        switch descriptor {
        case "idle": return .idle
        case "thinking": return .thinking
        case "responding": return .responding
        case "completed": return .completed
        default: return .idle
        }
    }
}
