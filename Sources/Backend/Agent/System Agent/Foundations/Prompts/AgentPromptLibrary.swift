import Foundation

struct AgentPromptLibrary: Sendable {
    static let codeReview = AgentPromptTemplate("Review the following code for potential issues: {{code}}")
    static let summarize = AgentPromptTemplate("Summarize the following text: {{text}}")
    static let explain = AgentPromptTemplate("Explain the following concept: {{concept}}")
}
