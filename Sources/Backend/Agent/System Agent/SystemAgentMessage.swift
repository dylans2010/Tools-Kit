import Foundation

struct SystemAgentMessage: Codable, Identifiable {
    enum Role: String, Codable {
        case system
        case user
        case assistant
        case tool
    }

    struct ToolCall: Codable, Identifiable {
        let id: UUID
        let name: String
        let input: [String: AnyCodable]

        init(id: UUID = UUID(), name: String, input: [String: Any]) {
            self.id = id
            self.name = name
            self.input = input.mapValues(AnyCodable.init)
        }
    }

    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date
    let toolCalls: [ToolCall]

    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date(), toolCalls: [ToolCall] = []) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.toolCalls = toolCalls
    }

    var chatMessage: ChatMessage {
        ChatMessage(role: role.rawValue, content: content, timestamp: timestamp)
    }
}
