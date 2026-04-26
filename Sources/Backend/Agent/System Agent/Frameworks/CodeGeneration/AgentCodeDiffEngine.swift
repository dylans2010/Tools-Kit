import Foundation

public final class AgentCodeDiffEngine {
    public init() {}

    public func generateDiff(original: String, modified: String) -> String {
        // Simple line-based diff generator
        let originalLines = original.components(separatedBy: .newlines)
        let modifiedLines = modified.components(separatedBy: .newlines)

        var diff = ""
        let maxLines = max(originalLines.count, modifiedLines.count)

        for i in 0..<maxLines {
            if i < originalLines.count && i < modifiedLines.count {
                if originalLines[i] != modifiedLines[i] {
                    diff += "- \(originalLines[i])\n+ \(modifiedLines[i])\n"
                }
            } else if i < originalLines.count {
                diff += "- \(originalLines[i])\n"
            } else if i < modifiedLines.count {
                diff += "+ \(modifiedLines[i])\n"
            }
        }
        return diff
    }
}
