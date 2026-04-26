import Foundation

struct AgentModelRegistry {
    struct ModelInfo: Codable, Identifiable {
        let id: String
        let name: String
        let contextWindow: Int
        let capabilities: Set<String>
    }

    private var models: [String: ModelInfo] = [:]

    init() {
        // Register default models
        register(ModelInfo(id: "gpt-4o", name: "GPT-4o", contextWindow: 128000, capabilities: ["vision", "tools"]))
        register(ModelInfo(id: "claude-3-5-sonnet", name: "Claude 3.5 Sonnet", contextWindow: 200000, capabilities: ["vision", "tools"]))
    }

    mutating func register(_ model: ModelInfo) {
        models[model.id] = model
    }

    func model(for id: String) -> ModelInfo? {
        models[id]
    }

    var allModels: [ModelInfo] {
        Array(models.values).sorted { $0.name < $1.name }
    }
}
