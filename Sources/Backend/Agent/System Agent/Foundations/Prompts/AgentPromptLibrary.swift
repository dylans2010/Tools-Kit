import Foundation

public struct AgentPromptLibrary {
    public static let codeReview = AgentPromptTemplate("Review the following code for potential issues: {{code}}")
    public static let summarize = AgentPromptTemplate("Summarize the following text: {{text}}")
    public static let explain = AgentPromptTemplate("Explain the following concept: {{concept}}")
}
