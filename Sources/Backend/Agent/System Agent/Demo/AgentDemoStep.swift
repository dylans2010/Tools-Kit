import Foundation

struct AgentDemoStep: Codable, Identifiable, Sendable {
    let id: UUID
    let title: String
    let content: String
    let delay: TimeInterval

    init(title: String, content: String, delay: TimeInterval = 1.0) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.delay = delay
    }
}
