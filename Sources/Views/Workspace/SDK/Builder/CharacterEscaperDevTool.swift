import SwiftUI

struct CharacterEscaperDevTool: DevTool {
    let id = "character-escaper"
    let name = "Character Escaper"
    let category: DevToolCategory = .utilities
    let icon = "chevron.left.forwardslash.chevron.right"
    let description = "Escape special characters for various contexts"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter text to escape") { input in "HTML: \(input.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;"))\nJSON: \(input.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n"))\nRegex: \(input.replacingOccurrences(of: ".", with: "\\.").replacingOccurrences(of: "*", with: "\\*"))" } }
}
