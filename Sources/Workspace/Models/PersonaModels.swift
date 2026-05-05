import Foundation

struct PersonaConfig: Codable {
    var name: String
    var instructions: String
    var baseModel: String
    var workspaceScope: [String] // List of folders or categories to index
}

struct PersonaInteraction: Codable, Identifiable {
    var id: UUID = UUID()
    var query: String
    var response: String
    var contextUsed: [String] // IDs of entities used for context
    var timestamp: Date = Date()
}
