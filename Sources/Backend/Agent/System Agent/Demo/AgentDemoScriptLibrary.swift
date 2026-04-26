import Foundation

struct AgentDemoScriptLibrary {
    static let basicHello = AgentDemoScript(name: "Basic Hello", steps: [
        AgentDemoStep(title: "Greeting", content: "Hello! How can I help you today?"),
        AgentDemoStep(title: "Capability", content: "I can help you write code or explain concepts.")
    ])
}
