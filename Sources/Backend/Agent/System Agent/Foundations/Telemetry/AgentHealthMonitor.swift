import Foundation

public final class AgentHealthMonitor {
    public enum Status {
        case healthy, degraded, unhealthy
    }

    private let aiService: AIService

    public init(aiService: AIService = .shared) {
        self.aiService = aiService
    }

    public func checkStatus() async -> Status {
        do {
            // Check if AI Service is responsive
            _ = try await aiService.processText(prompt: "health check", systemPrompt: "respond with ok")
            return .healthy
        } catch {
            AgentAPILogger.shared.log(.error, "Health check failed: \(error.localizedDescription)")
            return .unhealthy
        }
    }
}
