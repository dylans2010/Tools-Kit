import Foundation

struct AgentBundleValidator {
    func validate(identifier: String, version: String, tools: [String]) -> [String] {
        var issues: [String] = []
        if identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append("Bundle identifier must not be empty") }
        if version.split(separator: ".").count < 2 { issues.append("Version should follow semantic-style notation") }
        if tools.isEmpty { issues.append("Bundle must expose at least one tool") }
        let duplicates = Dictionary(grouping: tools, by: { $0.lowercased() }).filter { $1.count > 1 }.keys
        if !duplicates.isEmpty { issues.append("Duplicate tool names: \(duplicates.sorted().joined(separator: ", "))") }
        return issues
    }

    func isValid(identifier: String, version: String, tools: [String]) -> Bool {
        validate(identifier: identifier, version: version, tools: tools).isEmpty
    }
}
