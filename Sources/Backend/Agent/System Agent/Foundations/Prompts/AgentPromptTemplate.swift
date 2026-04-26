import Foundation

struct AgentPromptTemplate {
    var template: String

    func render(_ values: [String: String]) -> String {
        values.reduce(template) { partial, pair in
            partial.replacingOccurrences(of: "{{\(pair.key)}}", with: pair.value)
        }
    }
}
