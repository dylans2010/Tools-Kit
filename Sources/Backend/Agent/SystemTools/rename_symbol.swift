import Foundation

final class RenameSymbolTool: SystemTool {
    let name = "rename_symbol"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let oldSymbol = try requireString(input, key: "old_symbol")
        let newSymbol = try requireString(input, key: "new_symbol")
        let root = toolsWorkingDirectory(from: input)
        let files = enumerateFiles(root: root, allowedExtensions: ["swift", "m", "mm", "h", "c", "cpp"])
        let pattern = "\\b" + NSRegularExpression.escapedPattern(for: oldSymbol) + "\\b"
        let regex = try NSRegularExpression(pattern: pattern)
        var updatedFiles: [String] = []
        var replacements = 0

        for file in files {
            guard let content = try? String(contentsOf: file, encoding: .utf8) else { continue }
            let range = NSRange(content.startIndex..., in: content)
            let count = regex.numberOfMatches(in: content, range: range)
            if count == 0 { continue }
            let updated = regex.stringByReplacingMatches(in: content, range: range, withTemplate: newSymbol)
            try updated.write(to: file, atomically: true, encoding: .utf8)
            replacements += count
            updatedFiles.append(file.path.replacingOccurrences(of: root.path + "/", with: ""))
        }

        return successResponse(input: input, context: context, output: [
            "old_symbol": oldSymbol,
            "new_symbol": newSymbol,
            "replacement_count": replacements,
            "files_changed": updatedFiles
        ])
    }
}
