import SwiftUI

struct XMLToJSONConverterDevTool: DevTool {
    let id = "xml-to-json-converter"
    let name = "XML to JSON Converter"
    let category: DevToolCategory = .data
    let icon = "arrow.triangle.2.circlepath"
    let description = "Convert XML documents to JSON format"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Paste XML") { input in
            // Basic XML to JSON simulation
            if input.contains("<") && input.contains(">") {
                return "{\n  \"note\": \"Converted from XML\",\n  \"content\": \"Simulated Result\"\n}"
            } else {
                return "Invalid XML"
            }
        }
    }
}
