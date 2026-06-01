import Foundation

struct PersonaConfig: Codable {
    var name: String
    var instructions: String
    var baseModel: String
    var workspaceScope: [String] // List of folders or categories to index
    var isTrainingEnabled: Bool = true
    var trainingPrompt: String = ""
    var creativity: Double = 0.5
    var formality: Double = 0.5
    var humor: Double = 0.5
    var temperature: Double = 0.7
    var maxTokens: Int = 2048
    var webSearchEnabled: Bool = false
    var memoryEnabled: Bool = true
    var mcpToolsEnabled: Bool = false

    init(
        name: String,
        instructions: String,
        baseModel: String,
        workspaceScope: [String],
        isTrainingEnabled: Bool = true,
        trainingPrompt: String = "",
        creativity: Double = 0.5,
        formality: Double = 0.5,
        humor: Double = 0.5,
        temperature: Double = 0.7,
        maxTokens: Int = 2048,
        webSearchEnabled: Bool = false,
        memoryEnabled: Bool = true,
        mcpToolsEnabled: Bool = false
    ) {
        self.name = name
        self.instructions = instructions
        self.baseModel = baseModel
        self.workspaceScope = workspaceScope
        self.isTrainingEnabled = isTrainingEnabled
        self.trainingPrompt = trainingPrompt
        self.creativity = creativity
        self.formality = formality
        self.humor = humor
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.webSearchEnabled = webSearchEnabled
        self.memoryEnabled = memoryEnabled
        self.mcpToolsEnabled = mcpToolsEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case name, instructions, baseModel, workspaceScope, isTrainingEnabled, trainingPrompt
        case creativity, formality, humor, temperature, maxTokens, webSearchEnabled, memoryEnabled, mcpToolsEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        instructions = try container.decode(String.self, forKey: .instructions)
        baseModel = try container.decode(String.self, forKey: .baseModel)
        workspaceScope = try container.decode([String].self, forKey: .workspaceScope)
        isTrainingEnabled = try container.decodeIfPresent(Bool.self, forKey: .isTrainingEnabled) ?? true
        trainingPrompt = try container.decodeIfPresent(String.self, forKey: .trainingPrompt) ?? ""
        creativity = try container.decodeIfPresent(Double.self, forKey: .creativity) ?? 0.5
        formality = try container.decodeIfPresent(Double.self, forKey: .formality) ?? 0.5
        humor = try container.decodeIfPresent(Double.self, forKey: .humor) ?? 0.5
        temperature = try container.decodeIfPresent(Double.self, forKey: .temperature) ?? 0.7
        maxTokens = try container.decodeIfPresent(Int.self, forKey: .maxTokens) ?? 2048
        webSearchEnabled = try container.decodeIfPresent(Bool.self, forKey: .webSearchEnabled) ?? false
        memoryEnabled = try container.decodeIfPresent(Bool.self, forKey: .memoryEnabled) ?? true
        mcpToolsEnabled = try container.decodeIfPresent(Bool.self, forKey: .mcpToolsEnabled) ?? false
    }
}

struct PersonaInteraction: Codable, Identifiable {
    var id: UUID = UUID()
    var query: String
    var response: String
    var contextUsed: [String] // IDs of entities used for context
    var timestamp: Date = Date()
}

struct PersonaMessage: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var role: String // "user" or "assistant"
    var content: String
    var timestamp: Date = Date()
}

struct PersonaModelTraining: Codable, Identifiable {
    var id: UUID = UUID()
    var userQuery: String
    var aiResponse: String
    var timestamp: Date = Date()
}


struct PersonaChatThread: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var messages: [PersonaMessage]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        messages: [PersonaMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
