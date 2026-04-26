import Foundation

final class AnalyzeErrorsTool: SystemTool {
    let name = "analyze_errors"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let content: String
        if let log = input["log"] as? String {
            content = log
        } else {
            let fileURL = try resolveFileURL(from: input)
            content = try String(contentsOf: fileURL, encoding: .utf8)
        }

        let lines = content.components(separatedBy: .newlines)
        let errorLines = lines.filter { $0.localizedCaseInsensitiveContains("error") }
        let warningLines = lines.filter { $0.localizedCaseInsensitiveContains("warning") }
        let failureLines = lines.filter { $0.localizedCaseInsensitiveContains("failed") || $0.localizedCaseInsensitiveContains("failure") }

        return successResponse(input: input, context: context, output: [
            "total_lines": lines.count,
            "error_count": errorLines.count,
            "warning_count": warningLines.count,
            "failure_count": failureLines.count,
            "sample_errors": Array(errorLines.prefix(20))
        ])
    }
}
