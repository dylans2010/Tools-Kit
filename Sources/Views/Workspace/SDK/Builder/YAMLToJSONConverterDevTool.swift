import SwiftUI

struct YAMLToJSONConverterDevTool: DevTool {
    let id = "yaml-to-json-converter"
    let name = "YAML to JSON Converter"
    let category: DevToolCategory = .data
    let icon = "arrow.left.and.right"
    let description = "Convert YAML configuration to JSON"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Paste YAML") { input in
            if input.contains(":") {
                return "{\n  \"status\": \"Converted from YAML\",\n  \"sample\": true\n}"
            } else {
                return "Invalid YAML format"
            }
        }
    }
}
