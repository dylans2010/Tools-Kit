import SwiftUI

struct DiffMatchPatchDevTool: DevTool {
    let id = "diff-match-patch"
    let name = "Diff Match Patch"
    let category: DevToolCategory = .utilities
    let icon = "arrow.2.squarepath"
    let description = "Simple character-based text diff utility"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Original Text | New Text") { input in
            let parts = input.components(separatedBy: "|")
            guard parts.count == 2 else { return "Format: Original Text | New Text" }

            let old = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let new = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)

            return computeDiff(old: old, new: new)
        }
    }

    private func computeDiff(old: String, new: String) -> String {
        // Simple character-by-character diff for demonstration
        let oldChars = Array(old)
        let newChars = Array(new)
        var result = ""

        let commonCount = min(oldChars.count, newChars.count)
        for i in 0..<commonCount {
            if oldChars[i] == newChars[i] {
                result += "  \(oldChars[i])\n"
            } else {
                result += "- \(oldChars[i])\n"
                result += "+ \(newChars[i])\n"
            }
        }

        if oldChars.count > commonCount {
            for i in commonCount..<oldChars.count {
                result += "- \(oldChars[i])\n"
            }
        }

        if newChars.count > commonCount {
            for i in commonCount..<newChars.count {
                result += "+ \(newChars[i])\n"
            }
        }

        return result
    }
}
