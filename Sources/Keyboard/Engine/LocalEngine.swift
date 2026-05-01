import Foundation

class LocalEngine {
    private let contextAnalyzer = ContextAnalyzer()
    private let rewriteEngine = RewriteEngine()

    func processLocally(text: String) -> AIResponse {
        let analysis = contextAnalyzer.analyze(text: text)
        let grammarFixed = rewriteEngine.fixGrammar(text: text)

        let suggestion = Suggestion(
            originalText: text,
            suggestedText: grammarFixed,
            category: .grammar,
            score: 0.8
        )

        return AIResponse(
            result: grammarFixed,
            suggestions: [suggestion],
            analysis: analysis
        )
    }
}
