import Foundation

final class AgenticIntegrityValidationLayer {
    static let shared = AgenticIntegrityValidationLayer()

    private init() {}

    /// Validates that a tool output is not hardcoded or static.
    func validateToolOutput(_ output: AgenticToolOutput, from toolName: String) throws {
        // 1. Detect common static placeholders
        let staticPlaceholders = [
            "Successfully created task",
            "This is a summarized version",
            "Generated SwiftUI view"
        ]

        for placeholder in staticPlaceholders {
            if output.summary == placeholder {
                throw NSError(domain: "AgenticIntegrity", code: 403, userInfo: [NSLocalizedDescriptionKey: "Static output detected for \(toolName). Outputs must be dynamically generated from state or model."])
            }
        }

        // 2. Ensure non-empty results for critical tools
        if output.summary.isEmpty {
             throw NSError(domain: "AgenticIntegrity", code: 400, userInfo: [NSLocalizedDescriptionKey: "Tool \(toolName) produced an empty summary."])
        }
    }

    /// Detects if model reasoning appears to be hardcoded/faked.
    func validateModelReasoning(_ reasoning: String) throws {
        if reasoning.contains("Mocked logic for demonstration") {
             throw NSError(domain: "AgenticIntegrity", code: 403, userInfo: [NSLocalizedDescriptionKey: "Mocked model reasoning detected. Must use Foundation Models for generation."])
        }
    }
}
