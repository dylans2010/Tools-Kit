import SwiftUI

struct TOMLParserDevTool: DevTool {
    let id = "toml-parser"
    let name = "TOML Parser"
    let category: DevToolCategory = .data
    let icon = "doc.text"
    let description = "Parse and validate TOML configuration files"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Paste TOML content") { input in
            let lines = input.components(separatedBy: "\n")
            let sections = lines.filter { $0.hasPrefix("[") }.count
            let kvs = lines.filter { $0.contains("=") && !$0.hasPrefix("[") }.count
            return "Sections: \(sections)\nKey-Value Pairs: \(kvs)\nTotal Lines: \(lines.count)"
        }
    }
}
