import Foundation

struct IntegrationTool: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String = ""
    var description: String = ""
    var promptTemplate: String = ""
    var systemPrompt: String = "You are a helpful assistant."
    var temperature: Double = 0.7
    var aiModel: String = "openai/gpt-3.5-turbo"
    var isEnabled: Bool = true
    var createdAt: Date = Date()
}
