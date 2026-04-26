import Foundation

final class ExtractFunctionTool: SystemTool {
    let name = "extract_function"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let fileURL = try resolveFileURL(from: input)
        let functionName = try requireString(input, key: "function_name")
        guard let startLine = input["start_line"] as? Int,
              let endLine = input["end_line"] as? Int,
              startLine > 0, endLine >= startLine else {
            throw SystemToolError(message: "Invalid start_line/end_line", code: "invalid_range")
        }

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        var lines = content.components(separatedBy: .newlines)
        guard endLine <= lines.count else {
            throw SystemToolError(message: "Line range exceeds file length", code: "invalid_range")
        }

        let extractedBlock = Array(lines[(startLine - 1)...(endLine - 1)]).joined(separator: "\n")
        lines.replaceSubrange((startLine - 1)...(endLine - 1), with: ["\(functionName)()"])
        lines.append("")
        lines.append("private func \(functionName)() {")
        lines.append(contentsOf: extractedBlock.components(separatedBy: .newlines).map { "    \($0)" })
        lines.append("}")
        let updated = lines.joined(separator: "\n")
        try updated.write(to: fileURL, atomically: true, encoding: .utf8)

        return successResponse(input: input, context: context, output: [
            "path": fileURL.path,
            "function_name": functionName,
            "extracted_lines": endLine - startLine + 1
        ])
    }
}
