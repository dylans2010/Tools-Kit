import Foundation

struct AgentPromptTemplate {
    let template: String

    init(_ template: String) {
        self.template = template
    }

    func render(variables: [String: String]) -> String {
        var rendered = template
        for (key, value) in variables {
            rendered = rendered.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        return rendered
    }
}
