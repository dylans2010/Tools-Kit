import Foundation

final class CodeExplainTool: SystemTool {
    let name = "code_explain"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let fileURL = try resolveFileURL(from: input)
        let code = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = code.components(separatedBy: .newlines)
        let functionCount = lines.filter { $0.contains("func ") }.count
        let typeCount = lines.filter { $0.contains("class ") || $0.contains("struct ") || $0.contains("enum ") }.count
        let importCount = lines.filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("import ") }.count

        return successResponse(input: input, context: context, output: [
            "path": fileURL.path,
            "summary": "File has \(lines.count) lines, \(typeCount) type declarations, \(functionCount) functions, and \(importCount) imports.",
            "function_count": functionCount,
            "type_count": typeCount,
            "import_count": importCount
        ])
    }
}
