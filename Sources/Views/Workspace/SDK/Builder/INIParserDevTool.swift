import SwiftUI

struct INIParserDevTool: DevTool {
    let id = "ini-parser"
    let name = "INI Parser"
    let category: DevToolCategory = .data
    let icon = "gearshape.2"
    let description = "Parse and inspect INI configuration files"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Paste INI content") { input in
            let lines = input.components(separatedBy: "\n")
            let sections = lines.filter { $0.hasPrefix("[") }.count
            let props = lines.filter { $0.contains("=") && !$0.hasPrefix(";") }.count
            return "Sections: \(sections)\nProperties: \(props)\nComments: \(lines.filter { $0.hasPrefix(";") || $0.hasPrefix("#") }.count)"
        }
    }
}
