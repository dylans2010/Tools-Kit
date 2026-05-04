import Foundation

class AICodeAssistantManager {
    static let shared = AICodeAssistantManager()

    private init() {}

    func suggestFix(for error: String) async -> String {
        return await AIOrchestrator.shared.query(prompt: "Fix this code error: \(error)")
    }
}
