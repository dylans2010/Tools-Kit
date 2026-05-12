import Foundation
import FoundationModels

struct AgenticToolCodeModelBuilder: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "code_model_builder",
        description: "Generate Swift data models from a schema",
        category: "codegen",
        inputSchema: ["modelName": "String", "properties": "String"],
        producesCode: true
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let modelName = parameters["modelName"] ?? "GeneratedModel"
        let properties = parameters["properties"] ?? ""

        let session = LanguageModelSession(instructions: """
        You are a Swift data model generator. Generate complete, compilable Swift files with:
        1. All imports (Foundation, SwiftUI if needed)
        2. Codable conformance
        3. Identifiable conformance with UUID id
        4. Proper initializers
        5. Hashable/Equatable conformance where appropriate
        6. Documentation comments
        """)

        let prompt = """
        Generate a Swift data model named '\(modelName)'.
        Properties: \(properties)

        Include: Codable, Identifiable, initializer, and any computed properties.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Generated Swift model '\(modelName)'",
            generatedCode: response.content,
            metadata: ["modelName": modelName],
            dataPayload: ["properties": properties]
        )
    }
}
