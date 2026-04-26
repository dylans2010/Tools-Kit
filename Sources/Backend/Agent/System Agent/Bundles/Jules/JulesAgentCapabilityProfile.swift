import Foundation

public struct JulesAgentCapabilityProfile {
    public static let capabilities = AgentCapabilities(
        canUseTools: true,
        canProcessVision: true,
        canGenerateCode: true,
        canAccessInternet: false
    )
}
