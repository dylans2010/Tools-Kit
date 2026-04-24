import Foundation

final class CodeTransformer {
    private let jules = JulesProvider()

    func transform(action: ImportAction, apiKey: String) async throws -> String {
        guard action.action != .discard else { return "Skipped" }

        let prompt = """
        Transform the following Swift module from an external repository into ToolsKit architecture.

        Module Name: \(action.module.name)
        Original Path: \(action.module.path)
        Target Path: \(action.targetPath)
        Action: \(action.action.rawValue)

        Rules:
        - Use SwiftUI for all UI components.
        - Follow MVVM pattern.
        - Ensure all network calls are async/await.
        - No force-unwraps.
        - Add doc comments.
        """

        let session = try await jules.createSession(prompt: prompt, source: nil, apiKey: apiKey)
        return "Transformation session started: \(session.id)"
    }
}
