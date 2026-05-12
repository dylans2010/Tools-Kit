import Foundation
import FoundationModels

struct AgenticToolCodeArchitectureGenerator: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "code_architecture_generator",
        description: "Generate architectural scaffolding for a system",
        category: "codegen",
        inputSchema: ["systemName": "String", "pattern": "String"],
        producesCode: true
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let systemName = parameters["systemName"] ?? "System"
        let pattern = parameters["pattern"] ?? "MVVM"

        let session = LanguageModelSession(instructions: """
        You are a Swift architecture generator. Generate complete architectural scaffolding including:
        1. Protocol definitions
        2. Base classes/structs
        3. Dependency injection setup
        4. Service layer abstractions
        5. Data flow patterns
        6. All imports and complete file contents
        Support patterns: MVVM, MVC, VIPER, Clean Architecture, TCA.
        """)

        let prompt = """
        Generate architectural scaffolding for system '\(systemName)'.
        Pattern: \(pattern)

        Include all layers, protocols, and base types needed for the architecture.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Generated \(pattern) architecture for '\(systemName)'",
            generatedCode: response.content,
            metadata: ["systemName": systemName, "pattern": pattern],
            dataPayload: ["architecturePattern": pattern]
        )
    }
}
