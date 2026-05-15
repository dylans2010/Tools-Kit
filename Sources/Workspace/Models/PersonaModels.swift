import Foundation

struct PersonaConfig: Codable {
    var name: String
    var instructions: String
    var baseModel: String
    var workspaceScope: [String] // List of folders or categories to index
    var isTrainingEnabled: Bool = true
    var trainingPrompt: String = ""
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
