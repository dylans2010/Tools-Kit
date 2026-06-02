import SwiftUI

struct JSONSchemaGeneratorDevTool: DevTool {
    let id = "json-schema-gen"
    let name = "JSON Schema Generator"
    let category: DevToolCategory = .data
    let icon = "doc.text.magnifyingglass"
    let description = "Generate JSON Schema from a JSON instance"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Paste JSON instance") { input in
            guard let data = input.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) else {
                return "Invalid JSON"
            }
            return generateSchema(for: json)
        }
    }

    private func generateSchema(for json: Any) -> String {
        var schema: [String: Any] = ["$schema": "http://json-schema.org/draft-07/schema#"]
        schema.merge(typeInfo(for: json)) { (_, new) in new }
        let data = try! JSONSerialization.data(withJSONObject: schema, options: .prettyPrinted)
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func typeInfo(for value: Any) -> [String: Any] {
        if value is String { return ["type": "string"] }
        if value is Int { return ["type": "integer"] }
        if value is Double { return ["type": "number"] }
        if value is Bool { return ["type": "boolean"] }
        if let dict = value as? [String: Any] {
            var props: [String: Any] = [:]
            for (k, v) in dict { props[k] = typeInfo(for: v) }
            return ["type": "object", "properties": props]
        }
        if let arr = value as? [Any] {
            if let first = arr.first { return ["type": "array", "items": typeInfo(for: first)] }
            return ["type": "array"]
        }
        return ["type": "null"]
    }
}
