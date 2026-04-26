import Foundation

struct JulesAgentBundle {
    static let bundle = AgentBundle(
        id: "com.jules.agent",
        name: "Jules AI Agent",
        version: "1.0.0",
        tools: JulesAgentToolManifest.tools,
        capabilities: JulesAgentCapabilityProfile.capabilities
    )
}
