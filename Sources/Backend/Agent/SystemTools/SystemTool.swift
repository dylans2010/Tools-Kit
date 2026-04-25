import Foundation

/// Protocol for all system tools.
protocol SystemTool {
    var name: String { get }
    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse
}

/// Standard context for tool execution.
struct SystemToolContext: Codable {
    let workspaceId: String
    let sessionId: String
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case workspaceId = "workspace_id"
        case sessionId = "session_id"
        case timestamp
    }
}

/// Standard response structure for all system tools.
struct SystemToolResponse: Codable {
    let tool: String
    let status: String
    let requestId: String
    let input: [String: AnyCodable]
    let output: [String: AnyCodable]
    let error: SystemToolError?
    let context: SystemToolContext

    enum CodingKeys: String, CodingKey {
        case tool
        case status
        case requestId = "request_id"
        case input
        case output
        case error
        case context
    }
}

struct SystemToolError: Codable {
    let message: String
    let code: String
}

/// Type-erased Codable for handling dynamic JSON objects.
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dictionary = value as? [String: Any] {
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        } else {
            // Check for optional values that might be nil
            let mirror = Mirror(reflecting: value)
            if mirror.displayStyle == .optional {
                if mirror.children.isEmpty {
                    try container.encodeNil()
                } else {
                    let (_, unwrappedValue) = mirror.children.first!
                    try AnyCodable(unwrappedValue).encode(to: encoder)
                }
            } else {
                throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
            }
        }
    }
}
