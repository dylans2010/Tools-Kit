import Foundation

struct JulesAgentCapabilityProfile {
    static let capabilities = AgentCapabilities(
        canUseTools: true,
        canProcessVision: true,
        canGenerateCode: true,
        canAccessInternet: false
    )
}
