import Foundation

struct SystemAgentBundle: Sendable {
    static let bundle = AgentBundle(
        id: "com.system.agent",
        name: "System Agent",
        version: "1.0.0",
        tools: SystemAgentToolManifest.tools,
        capabilities: SystemAgentCapabilityProfile.capabilities
    )
}
