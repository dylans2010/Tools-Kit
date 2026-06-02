import SwiftUI

struct URLQueryBuilderDevTool: DevTool {
    let id = "url-query-builder"
    let name = "URL Query Builder"
    let category: DevToolCategory = .utilities
    let icon = "plus.circle"
    let description = "Build and encode URL query strings from parameters"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "key1=val1, key2=val2") { input in
            let pairs = input.components(separatedBy: ",")
            let query = pairs.map { $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "=", with: ":") }.joined(separator: "&")
            return "https://example.com/?\(query)"
        }
    }
}
