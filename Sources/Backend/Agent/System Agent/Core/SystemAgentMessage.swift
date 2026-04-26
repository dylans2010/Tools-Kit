import Foundation

struct SystemAgentMessage: Codable, Identifiable {
    enum Role: Codable {
        case system
        case user
        case assistant
        case toolCall(name: String, input: [String: AnyCodable])
        case toolResult(toolName: String, result: String)
        case failed(message: String)

        private enum CodingKeys: String, CodingKey {
            case type
            case name
            case input
            case result
            case message
        }

        private enum Kind: String, Codable {
            case system
            case user
            case assistant
            case toolCall
            case toolResult
            case failed
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let kind = try container.decode(Kind.self, forKey: .type)
            switch kind {
            case .system:
                self = .system
            case .user:
                self = .user
            case .assistant:
                self = .assistant
            case .toolCall:
                let name = try container.decode(String.self, forKey: .name)
                let input = try container.decode([String: AnyCodable].self, forKey: .input)
                self = .toolCall(name: name, input: input)
            case .toolResult:
                let toolName = try container.decode(String.self, forKey: .name)
                let result = try container.decode(String.self, forKey: .result)
                self = .toolResult(toolName: toolName, result: result)
            case .failed:
                let message = try container.decode(String.self, forKey: .message)
                self = .failed(message: message)
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .system:
                try container.encode(Kind.system, forKey: .type)
            case .user:
                try container.encode(Kind.user, forKey: .type)
            case .assistant:
                try container.encode(Kind.assistant, forKey: .type)
            case .toolCall(let name, let input):
                try container.encode(Kind.toolCall, forKey: .type)
                try container.encode(name, forKey: .name)
                try container.encode(input, forKey: .input)
            case .toolResult(let toolName, let result):
                try container.encode(Kind.toolResult, forKey: .type)
                try container.encode(toolName, forKey: .name)
                try container.encode(result, forKey: .result)
            case .failed(let message):
                try container.encode(Kind.failed, forKey: .type)
                try container.encode(message, forKey: .message)
            }
        }
    }

    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date

    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    var chatMessage: ChatMessage {
        ChatMessage(role: chatRole, content: serializedContentForModel, timestamp: timestamp)
    }

    private var chatRole: String {
        switch role {
        case .system:
            return "system"
        case .user, .toolResult:
            return "user"
        case .assistant, .toolCall:
            return "assistant"
        case .failed:
            return "assistant"
        }
    }

    private var serializedContentForModel: String {
        switch role {
        case .toolCall(let name, let input):
            let mapped = input.mapValues(\.value)
            let json = (try? JSONSerialization.data(withJSONObject: ["tool": name, "input": mapped], options: [.sortedKeys]))
                .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
            return "Tool call: \(json)"
        case .toolResult(let toolName, let result):
            return "Tool result from \(toolName): \(result)"
        case .failed(let message):
            return "Error: \(message)"
        default:
            return content
        }
    }
}
