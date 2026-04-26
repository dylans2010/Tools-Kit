import Foundation

public struct AgentModelRegistry {
    public struct ModelInfo: Codable, Identifiable {
        public let id: String
        public let name: String
        public let contextWindow: Int
        public let capabilities: Set<String>
    }

    private var models: [String: ModelInfo] = [:]

    public init() {
        // Register default models
        register(ModelInfo(id: "gpt-4o", name: "GPT-4o", contextWindow: 128000, capabilities: ["vision", "tools"]))
        register(ModelInfo(id: "claude-3-5-sonnet", name: "Claude 3.5 Sonnet", contextWindow: 200000, capabilities: ["vision", "tools"]))
    }

    public mutating func register(_ model: ModelInfo) {
        models[model.id] = model
    }

    public func model(for id: String) -> ModelInfo? {
        models[id]
    }

    public var allModels: [ModelInfo] {
        Array(models.values).sorted { $0.name < $1.name }
    }
}
