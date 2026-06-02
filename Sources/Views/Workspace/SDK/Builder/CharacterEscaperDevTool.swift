import SwiftUI

struct CharacterEscaperDevTool: DevTool {
    let id = "character-escaper"
    let name = "Character Escaper"
    let category: DevToolCategory = .utilities
    let icon = "chevron.left.forwardslash.chevron.right"
    let description = "Escape special characters for various contexts"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter text to escape") { input in
            let html = input.replacingOccurrences(of: "&", with: "&amp;")
                            .replacingOccurrences(of: "<", with: "&lt;")
                            .replacingOccurrences(of: ">", with: "&gt;")
            let json = input.replacingOccurrences(of: "\"", with: "\\\"")
                            .replacingOccurrences(of: "\n", with: "\\n")
            let regex = input.replacingOccurrences(of: ".", with: "\\.")
                             .replacingOccurrences(of: "*", with: "\\*")
            return "HTML: \(html)\nJSON: \(json)\nRegex: \(regex)"
        }
    }
}
