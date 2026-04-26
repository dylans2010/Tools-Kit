import Foundation

enum AgentBundleRegistry {
    static func currentBundle() -> AgentBundle {
        AgentBundle(identifier: "com.toolskit.agent.system", name: "System Agent", modelIdentifier: "default", version: "1.0.0")
    }
}
