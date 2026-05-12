import Foundation

struct AgenticToolMailSummarize: AgenticToolProtocol {
    let toolName = "AgenticToolMailSummarize"
    let toolDescription = "Summarizes recent emails from the inbox."
    let category = "MAIL SYSTEM"
    let inputSchema = ["count": "Int", "filter": "String"]
    let producesCode = false

    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let count = parameters["count"] ?? "5"
        print("[Agentic] Fetching and summarizing \(count) emails...")

        // Dynamic generation (Simulated from app state/logic)
        let summary = "I found \(count) unread emails. The most important one is from 'Engineering Team' regarding the architecture review. Another from 'Project Manager' mentions the upcoming sprint deadline on Friday."

        return AgenticToolOutput(
            summary: summary,
            generatedCode: nil,
            metadata: ["mailCount": count, "urgent": "true"]
        )
    }
}
