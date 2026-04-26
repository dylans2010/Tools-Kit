import Foundation

public struct AgentPromptTemplate {
    public let template: String

    public init(_ template: String) {
        self.template = template
    }

    public func render(variables: [String: String]) -> String {
        var rendered = template
        for (key, value) in variables {
            rendered = rendered.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        return rendered
    }
}
