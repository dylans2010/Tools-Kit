import SwiftUI

struct LocalizationHelperDevTool: DevTool {
    let id = "localization-helper"
    let name = "Localization Helper"
    let category: DevToolCategory = .data
    let icon = "character.book.closed"
    let description = "Generate Localizable.strings entries from text"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter key=value pairs") { input in
            input.components(separatedBy: .newlines).map { line in
                let parts = line.components(separatedBy: "=")
                guard parts.count == 2 else { return "" }
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let val = parts[1].trimmingCharacters(in: .whitespaces)
                return "\"\(key)\" = \"\(val)\";"
            }.joined(separator: "\n")
        }
    }
}
