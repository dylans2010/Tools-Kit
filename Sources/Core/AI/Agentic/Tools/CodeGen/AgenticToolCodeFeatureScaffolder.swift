import Foundation
import FoundationModels

struct AgenticToolCodeFeatureScaffolder: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "code_feature_scaffolder",
        description: "Scaffold a complete feature module",
        category: "codegen",
        inputSchema: ["featureName": "String", "components": "String"],
        producesCode: true
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let featureName = parameters["featureName"] ?? "NewFeature"
        let components = parameters["components"] ?? "view,model,viewmodel"

        let session = LanguageModelSession(instructions: """
        You are a Swift feature scaffolding engine. Generate complete, compilable feature modules including:
        1. Data models with Codable/Identifiable
        2. ViewModel with @Observable or ObservableObject
        3. SwiftUI Views with proper state management
        4. Service layer if needed
        5. All imports and full file structure
        Generate each component as a separate, clearly labeled section.
        """)

        let prompt = """
        Scaffold a complete feature module named '\(featureName)'.
        Components: \(components)

        Generate all files needed for a production-ready feature including models, views, and logic.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Scaffolded feature '\(featureName)' with components: \(components)",
            generatedCode: response.content,
            metadata: ["featureName": featureName, "components": components],
            dataPayload: ["componentCount": "\(components.components(separatedBy: ",").count)"]
        )
    }
}
