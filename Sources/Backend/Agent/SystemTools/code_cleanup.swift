import Foundation

final class CodeCleanupTool: SystemTool {
    let name = "code_cleanup"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let fileURL = try resolveFileURL(from: input)
        let original = try String(contentsOf: fileURL, encoding: .utf8)
        let cleaned = original
            .components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression) }
            .joined(separator: "\n")

        if cleaned != original {
            try cleaned.write(to: fileURL, atomically: true, encoding: .utf8)
        }

        return successResponse(input: input, context: context, output: [
            "path": fileURL.path,
            "modified": cleaned != original,
            "characters_removed": max(0, original.count - cleaned.count)
        ])
    }
}
