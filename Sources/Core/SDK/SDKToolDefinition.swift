import Foundation

/// Defines a standalone tool within the SDK.
public struct SDKToolDefinition: Identifiable, Codable {
    public var id: UUID
    public var name: String
    public var description: String
    public var category: ToolCategory
    public var inputs: [ToolParameter]
    public var outputs: [ToolParameter]
    public var steps: [SDKExecutionStep]

    public init(id: UUID = UUID(), name: String, description: String, category: ToolCategory, inputs: [ToolParameter], outputs: [ToolParameter], steps: [SDKExecutionStep]) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.inputs = inputs
        self.outputs = outputs
        self.steps = steps
    }
}

public struct SDKExecutionStep: Codable, Identifiable {
    public let id: UUID
    public let actionID: String
    public let inputMapping: [String: String]
}
