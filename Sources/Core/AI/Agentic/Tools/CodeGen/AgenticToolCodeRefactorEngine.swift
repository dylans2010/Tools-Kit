import Foundation
import FoundationModels

struct AgenticToolCodeRefactorEngine: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "code_refactor_engine",
        description: "Refactor existing Swift code using AI",
        category: "codegen",
        inputSchema: ["sourceCode": "String", "refactorType": "String"],
        producesCode: true
    )

    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let sourceCode = parameters["sourceCode"] ?? ""
        let refactorType = parameters["refactorType"] ?? "clean"

        let session = LanguageModelSession(instructions: """
        You are a Swift code refactoring engine. Refactor code while:
        1. Preserving all functionality
        2. Improving readability and maintainability
        3. Following Swift best practices and conventions
        4. Adding proper documentation
        5. Optimizing performance where possible
        Output the complete refactored code with all imports.
        """)

        let prompt = """
        Refactor this Swift code.
        Refactor type: \(refactorType)

        Source code:
        \(sourceCode)

        Produce the complete refactored version.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Refactored code using '\(refactorType)' strategy",
            generatedCode: response.content,
            metadata: ["refactorType": refactorType, "inputLength": "\(sourceCode.count)"],
            dataPayload: ["refactorType": refactorType]
        )
    }
}
