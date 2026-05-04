import Foundation
import Combine

/// Central intelligence engine that performs cross-app reasoning.
final class AIOrchestrator: ObservableObject {
    static let shared = AIOrchestrator()

    @Published private(set) var globalInsights: [IntelligenceInsight] = []
    @Published private(set) var isAnalyzing = false

    private let aiService = AIService.shared

    private init() {
        refreshInsights()
    }

    func refreshInsights() {
        isAnalyzing = true
        // Simulated cross-app reasoning
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.globalInsights = [
                IntelligenceInsight(
                    id: UUID(),
                    title: "Notes need organizing",
                    description: "You have 5 unorganized notes from the 'Meeting' folder.",
                    priority: .medium,
                    category: .productivity,
                    action: AIAction(type: "navigate", payload: ["target": "notes"])
                ),
                IntelligenceInsight(
                    id: UUID(),
                    title: "Security Alert",
                    description: "3 plugins have unreviewed permissions.",
                    priority: .high,
                    category: .security,
                    action: AIAction(type: "navigate", payload: ["target": "plugins"])
                )
            ]
            self.isAnalyzing = false
        }
    }

    func performCrossAppQuery(_ query: String, apps: Set<String>) async throws -> String {
        // Collect context from all apps
        let context = "Context from \(apps.joined(separator: ", ")): ..."
        let prompt = "Based on the global context: \(context). Query: \(query)"
        return try await aiService.generateResponse(prompt: prompt)
    }
}
