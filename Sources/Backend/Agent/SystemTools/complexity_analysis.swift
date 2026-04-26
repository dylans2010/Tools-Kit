import Foundation

final class ComplexityAnalysisTool: SystemTool {
    let name = "complexity_analysis"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let fileURL = try resolveFileURL(from: input)
        let code = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = code.components(separatedBy: .newlines)
        let decisionTokens = ["if ", "guard ", "switch ", "case ", "for ", "while ", "catch "]
        var score = 1
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            for token in decisionTokens where trimmed.contains(token) {
                score += 1
            }
        }
        return successResponse(input: input, context: context, output: [
            "path": fileURL.path,
            "cyclomatic_estimate": score,
            "line_count": lines.count,
            "risk_level": score > 20 ? "high" : (score > 10 ? "medium" : "low")
        ])
    }
}
