import Foundation
import FoundationModels

struct AgenticToolCodeSwiftUIViewGenerator: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "code_swiftui_view_generator",
        description: "Generate a complete SwiftUI view from a description",
        category: "codegen",
        inputSchema: ["viewDescription": "String", "viewName": "String"],
        producesCode: true
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let viewDescription = parameters["viewDescription"] ?? ""
        let viewName = parameters["viewName"] ?? "GeneratedView"

        let session = LanguageModelSession(instructions: """
        You are an expert SwiftUI code generator. Generate complete, compilable Swift files.
        Every generated file MUST include:
        1. All necessary import statements (import SwiftUI, import Foundation, etc.)
        2. Complete struct definition conforming to View protocol
        3. Full body implementation
        4. Any required supporting types, models, or view modifiers
        5. Preview provider
        Generate production-quality code with proper state management and accessibility.
        """)

        let prompt = """
        Generate a complete SwiftUI view named '\(viewName)'.
        Description: \(viewDescription)

        Requirements:
        - Full compilable Swift file
        - All imports included
        - Proper @State/@Binding usage
        - VoiceOver accessibility
        - Dynamic Type support
        - Dark mode compatible
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Generated SwiftUI view '\(viewName)'",
            generatedCode: response.content,
            metadata: ["viewName": viewName],
            dataPayload: ["viewDescription": viewDescription]
        )
    }
}
