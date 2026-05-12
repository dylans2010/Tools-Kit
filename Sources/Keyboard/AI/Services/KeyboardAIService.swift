import Foundation

class KeyboardAIService {
    nonisolated(unsafe) static let shared = KeyboardAIService()
    private let framework = KeyboardAIFramework()

    func fetchIntelligence(for text: String, mode: AccessMode) async -> AIResponse {
        if mode == .ai {
            let analysis = await framework.analyze(text: text)
            let suggestions = await framework.generateSuggestions(text: text)
            let rewrite = await framework.rewrite(text: text, style: .standard)

            return AIResponse(result: rewrite, suggestions: suggestions, analysis: analysis)
        } else {
            return framework.processLocal(text: text)
        }
    }

    func applyTransformation(text: String, style: RewriteStyle) async -> String {
        return await framework.rewrite(text: text, style: style)
    }

    func generateSmartReplies(text: String) async -> [String] {
        return await framework.generateReplies(text: text)
    }

    func convertContent(text: String, type: ConversionType) async -> String {
        return await framework.convert(text: text, to: type)
    }
}
