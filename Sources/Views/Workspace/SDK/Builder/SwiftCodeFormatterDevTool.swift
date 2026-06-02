import SwiftUI

struct SwiftCodeFormatterDevTool: DevTool {
    let id = "swift-code-formatter"
    let name = "Swift Code Formatter"
    let category: DevToolCategory = .automation
    let icon = "chevron.left.forwardslash.chevron.right"
    let description = "Basic indentation and spacing formatter for Swift snippets"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Paste Swift code") { input in
            var indent = 0
            var output = ""
            for line in input.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("}") { indent = max(0, indent - 1) }
                output += String(repeating: "    ", count: indent) + trimmed + "\n"
                if trimmed.hasSuffix("{") { indent += 1 }
            }
            return output
        }
    }
}
