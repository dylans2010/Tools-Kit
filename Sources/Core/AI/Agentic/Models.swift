import Foundation
// import FoundationModels // Note: FoundationModels is part of a restricted environment, typically Apple's private/early access SDKs.

// @Generable // Macro for structured output enforcement
struct AgenticModelResponse {
    var message: String
    var actions: [AgenticModelAction]
    var isComplete: Bool
}

struct AgenticModelAction {
    var toolName: String
    var parameters: [String: String]
}

// @Generable
struct AgenticToolOutput {
    var summary: String
    var generatedCode: String?
    var metadata: [String: String]
}
