import Foundation

public struct AgentDemoStep: Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let content: String
    public let delay: TimeInterval

    public init(title: String, content: String, delay: TimeInterval = 1.0) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.delay = delay
    }
}
