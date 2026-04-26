import Foundation

public struct AgentToolCallParser {
    public init() {}

    public func parse(_ jsonString: String) throws -> AgentToolCall {
        guard let data = jsonString.data(using: .utf8) else {
            throw AgentValidationError.invalidFormat("tool_call")
        }
        let dict = try JSONDecoder().decode([String: AnyCodable].self, from: data)
        guard let name = dict["tool"]?.value as? String else {
            throw AgentValidationError.missingRequiredField("tool")
        }
        let input = dict["input"]?.value as? [String: AnyCodable] ?? [:]
        return AgentToolCall(name: name, input: input)
    }
}
