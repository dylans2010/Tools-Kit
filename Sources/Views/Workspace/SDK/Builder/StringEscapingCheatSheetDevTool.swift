import SwiftUI

struct StringEscapingCheatSheetDevTool: DevTool {
    let id = "string-escaping"
    let name = "String Escaping Cheat Sheet"
    let category: DevToolCategory = .utilities
    let icon = "text.quote.rtl"
    let description = "Cheat sheet for common string escaping rules"

    func render() -> some View {
        List {
            Text("Swift: \"\\\"Hello\\\"\"")
            Text("HTML: &lt;tag&gt;")
            Text("URL: %20 (Space)")
            Text("Regex: \\. (Period)")
        }
    }
}
