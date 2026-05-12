import Foundation
import FoundationModels

struct AgenticToolCodeModuleAssembler: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "code_module_assembler",
        description: "Assemble multiple generated components into a module",
        category: "codegen",
        inputSchema: ["moduleName": "String", "componentIds": "String"],
        producesCode: true
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let moduleName = parameters["moduleName"] ?? "AssembledModule"
        let componentIdsStr = parameters["componentIds"] ?? ""
        let componentIds = componentIdsStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        let session = LanguageModelSession(instructions: """
        You are a Swift module assembler. Combine components into a cohesive module with:
        1. Unified import statements
        2. Proper namespace organization
        3. Inter-component wiring
        4. Public API surface definition
        5. Module initialization and configuration
        6. Complete, compilable Swift code
        """)

        let prompt = """
        Assemble a Swift module named '\(moduleName)'.
        Components to integrate: \(componentIds.joined(separator: ", "))

        Generate:
        1. Module entry point
        2. Component integration layer
        3. Public API
        4. Internal wiring
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Assembled module '\(moduleName)' from \(componentIds.count) components",
            generatedCode: response.content,
            metadata: ["moduleName": moduleName, "componentCount": "\(componentIds.count)"],
            dataPayload: ["components": componentIdsStr]
        )
    }
}
