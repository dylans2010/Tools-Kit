import XCTest
@testable import ToolsKit

final class KeyboardValidationTests: XCTestCase {
    func testContextAnalyzer() {
        let analyzer = ContextAnalyzer()
        let text = "Please send the report ASAP!"
        let analysis = analyzer.analyze(text: text)

        XCTAssertEqual(analysis.intent, "Request")
        XCTAssertEqual(analysis.urgency, "High")
        XCTAssertEqual(analysis.formality, "Informal")
    }

    func testRewriteEngine() {
        let engine = RewriteEngine()
        let text = "Hello"
        let formal = engine.rewrite(text: text, style: .formal)

        XCTAssertTrue(formal.contains("Respected colleague"))
    }

    func testSuggestionEngine() {
        let engine = SuggestionEngine()
        let analysis = TextAnalysis(intent: "Statement", sentiment: "Neutral", urgency: "Low", formality: "Informal", score: 0.5)
        let suggestions = engine.generateSuggestions(text: "test", analysis: analysis)

        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.count <= 3)
    }
}
