import SwiftUI

struct JSONSchemaGeneratorDevTool: DevTool {
    let id = "json-schema-generator"
    let name = "JSON Schema Generator"
    let category: DevToolCategory = .data
    let icon = "doc.text.below.ecg.fill"
    let description = "Generate JSON Schema from a JSON sample"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Paste JSON sample") { input in
            guard let data = input.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return "Invalid JSON"
            }
            var schema = "{\n  \"$schema\": \"http://json-schema.org/draft-07/schema#\",\n  \"type\": \"object\",\n  \"properties\": {\n"
            for (key, value) in json {
                let type: String
                if value is String { type = "string" }
                else if value is Int { type = "integer" }
                else if value is Double { type = "number" }
                else if value is Bool { type = "boolean" }
                else if value is [Any] { type = "array" }
                else { type = "object" }
                schema += "    \"\(key)\": { \"type\": \"\(type)\" },\n"
            }
            schema += "  }\n}"
            return schema
        }
    }
}
