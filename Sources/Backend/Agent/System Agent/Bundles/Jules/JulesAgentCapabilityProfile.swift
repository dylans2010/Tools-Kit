import Foundation

struct JulesAgentCapabilityProfile: Sendable {
    static let capabilities = AgentCapabilities(
        canUseTools: true,
        canProcessVision: true,
        canGenerateCode: true,
        canAccessInternet: false
    )
}
