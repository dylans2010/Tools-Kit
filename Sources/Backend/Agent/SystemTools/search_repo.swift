import Foundation

final class SearchRepoTool: SystemTool {
    let name = "search_repo"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        guard let query = (input["query"] as? String) ?? (input["pattern"] as? String), !query.isEmpty else {
            throw SystemToolError.missingParameter("query")
        }
        let root = toolsWorkingDirectory(from: input)
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            throw SystemToolError(message: "Unable to enumerate files", code: "enumeration_failed")
        }
        let caseSensitive = input["caseSensitive"] as? Bool ?? false
        let needle = caseSensitive ? query : query.lowercased()
        var matches: [String] = []
        while let fileURL = enumerator.nextObject() as? URL {
            guard fileURL.pathExtension == "swift" || fileURL.pathExtension == "md" || fileURL.pathExtension == "txt" else { continue }
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
            for (idx, line) in lines.enumerated() {
                let candidate = caseSensitive ? String(line) : String(line).lowercased()
                if candidate.contains(needle) {
                    matches.append("\(fileURL.path.replacingOccurrences(of: root.path + "/", with: "")):\(idx + 1): \(line)")
                }
            }
        }
        return successResponse(input: input, context: context, output: [
            "matches": matches,
            "count": matches.count,
            "query": query
        ])
    }
}
