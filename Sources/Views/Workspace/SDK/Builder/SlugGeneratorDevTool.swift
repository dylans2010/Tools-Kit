import SwiftUI

struct SlugGeneratorDevTool: DevTool {
    let id = "slug-generator"
    let name = "Slug Generator"
    let category: DevToolCategory = .utilities
    let icon = "link.circle"
    let description = "Generate URL-friendly slugs from text"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter text to slugify") { $0.lowercased().replacingOccurrences(of: " ", with: "-").filter { $0.isLetter || $0.isNumber || $0 == "-" } } }
}
