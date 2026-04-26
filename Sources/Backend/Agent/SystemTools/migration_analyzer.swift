import Foundation

final class MigrationAnalyzerTool: SystemTool {
    let name = "migration_analyzer"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let root = toolsWorkingDirectory(from: input)
        let files = enumerateFiles(root: root, allowedExtensions: ["swift", "m", "mm", "kt", "java", "js", "ts"])
        let deprecatedPatterns = (input["deprecated_patterns"] as? [String]) ?? ["UIWebView", "NSURLConnection", "dispatch_get_global_queue"]
        var matches: [String: [String]] = [:]

        for file in files {
            guard let content = try? String(contentsOf: file, encoding: .utf8) else { continue }
            let lines = content.components(separatedBy: .newlines)
            for (index, line) in lines.enumerated() {
                for pattern in deprecatedPatterns where line.contains(pattern) {
                    let relPath = file.path.replacingOccurrences(of: root.path + "/", with: "")
                    matches[pattern, default: []].append("\(relPath):\(index + 1)")
                }
            }
        }

        return successResponse(input: input, context: context, output: [
            "root": root.path,
            "deprecated_patterns": deprecatedPatterns,
            "hits": matches,
            "migration_ready": matches.isEmpty
        ])
    }
}
