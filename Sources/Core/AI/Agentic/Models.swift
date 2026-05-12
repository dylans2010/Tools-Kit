import Foundation

struct AgenticModelResponse {
    var message: String
    var actions: [AgenticModelAction]
    var isComplete: Bool
}

struct AgenticModelAction {
    var toolName: String
    var parameters: [String: String]
}

struct AgenticToolOutput {
    var summary: String
    var generatedCode: String?
    var metadata: [String: String]
}
