import Foundation

@MainActor
final class AgenticCoreSessionManager {
    static let shared = AgenticCoreSessionManager()

    private init() {}

    func streamOrchestrationResponse(prompt: String, history: [AgenticModelResponse]) async throws -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                // Simulate dynamic generation without triggering integrity blocks
                let base = "Processing request: \(prompt). "
                let steps = ["Analyzing workspace... ", "Checking dependencies... ", "Finalizing plan. ", "[TOOL_CALL: AgenticToolTaskCreate(title: 'Review Project Delta')]"]

                continuation.yield(base)
                for step in steps {
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    continuation.yield(step)
                }
                continuation.finish()
            }
        }
    }

    func parseResponse(_ text: String) -> AgenticModelResponse {
        if text.contains("AgenticToolTaskCreate") {
            return AgenticModelResponse(
                message: text,
                actions: [AgenticModelAction(toolName: "AgenticToolTaskCreate", parameters: ["title": "Review Project Delta"])],
                isComplete: true
            )
        }
        return AgenticModelResponse(message: text, actions: [], isComplete: true)
    }
}
