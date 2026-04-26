import Foundation

final class InlineFunctionTool: SystemTool {
    let name = "inline_function"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let fileURL = try resolveFileURL(from: input)
        let functionName = try requireString(input, key: "function_name")
        var code = try String(contentsOf: fileURL, encoding: .utf8)

        let escapedName = NSRegularExpression.escapedPattern(for: functionName)
        let bodyPattern = "func\\s+\(escapedName)\\s*\\(\\)\\s*->\\s*[^\\{]+\\{\\s*return\\s+(.+?)\\s*\\}"
        let bodyRegex = try NSRegularExpression(pattern: bodyPattern, options: [.dotMatchesLineSeparators])
        let range = NSRange(code.startIndex..., in: code)
        guard let match = bodyRegex.firstMatch(in: code, options: [], range: range),
              let exprRange = Range(match.range(at: 1), in: code),
              let wholeRange = Range(match.range(at: 0), in: code) else {
            throw SystemToolError(message: "Only single-expression return functions are supported for inlining.", code: "unsupported_shape")
        }

        let expression = String(code[exprRange])
        code.removeSubrange(wholeRange)
        code = code.replacingOccurrences(of: "\(functionName)()", with: "(\(expression))")
        try code.write(to: fileURL, atomically: true, encoding: .utf8)

        return successResponse(input: input, context: context, output: [
            "path": fileURL.path,
            "function_name": functionName,
            "inlined_expression": expression
        ])
    }
}
