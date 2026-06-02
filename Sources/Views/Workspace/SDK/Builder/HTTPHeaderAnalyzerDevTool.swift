import SwiftUI

struct HTTPHeaderAnalyzerDevTool: DevTool {
    let id = "http-header-analyzer"
    let name = "HTTP Header Analyzer"
    let category: DevToolCategory = .networking
    let icon = "list.bullet.rectangle.portrait"
    let description = "Analyze and validate HTTP response headers"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Paste HTTP headers") { input in let headers = input.components(separatedBy: "\n").filter { $0.contains(":") }; return "Headers found: \(headers.count)\n" + headers.map { "  \($0.trimmingCharacters(in: .whitespaces))" }.joined(separator: "\n") } }
}
