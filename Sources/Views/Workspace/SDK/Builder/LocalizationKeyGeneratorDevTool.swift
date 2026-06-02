import SwiftUI

struct LocalizationKeyGeneratorDevTool: DevTool {
    let id = "localization-key-generator"
    let name = "Localization Key Generator"
    let category: DevToolCategory = .automation
    let icon = "character.book.closed"
    let description = "Generate LocalizedStringKey code from raw strings"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter key name") { input in
            let key = input.isEmpty ? "hello_world" : input
            return "static let \(key) = NSLocalizedString(\"\(key)\", comment: \"\")"
        }
    }
}
