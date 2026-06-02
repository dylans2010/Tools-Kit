import SwiftUI

struct JSONToSwiftModelDevTool: DevTool {
    let id = "json-to-swift"
    let name = "JSON to Swift Model"
    let category: DevToolCategory = .data
    let icon = "braces"
    let description = "Generate Swift Codable models from JSON input"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Paste JSON here") { input in
            guard let data = input.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return "Invalid JSON object"
            }
            return generateSwiftModel(from: json, name: "GeneratedModel")
        }
    }

    private func generateSwiftModel(from dict: [String: Any], name: String) -> String {
        var result = "struct \(name): Codable {\n"
        for (key, value) in dict {
            let type: String
            if value is String { type = "String" }
            else if value is Int { type = "Int" }
            else if value is Double { type = "Double" }
            else if value is Bool { type = "Bool" }
            else if let subDict = value as? [String: Any] {
                type = key.capitalized
                result = generateSwiftModel(from: subDict, name: type) + "\n\n" + result
            }
            else { type = "AnyCodable" }
            result += "    let \(key): \(type)\n"
        }
        result += "}"
        return result
    }
}
