import SwiftUI

struct CURLConverterDevTool: DevTool {
    let id = "curl-converter"
    let name = "cURL Converter"
    let category: DevToolCategory = .networking
    let icon = "terminal.fill"
    let description = "Convert cURL commands to URL request code"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Paste cURL command") { input in var result = "// Swift URLRequest\n"; let url = input.components(separatedBy: " ").first(where: { $0.hasPrefix("http") }) ?? "https://api.example.com"; result += "var request = URLRequest(url: URL(string: \"\(url)\")!)\n"; if input.contains("-X POST") { result += "request.httpMethod = \"POST\"\n" }; if input.contains("-H") { result += "// Headers detected\n" }; return result } }
}
