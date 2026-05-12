import Foundation

struct AgentCapabilities: Codable, Equatable, Sendable {
    var canUseTools: Bool
    var canProcessVision: Bool
    var canGenerateCode: Bool
    var canAccessInternet: Bool

    static var none: AgentCapabilities {
        AgentCapabilities(canUseTools: false, canProcessVision: false, canGenerateCode: false, canAccessInternet: false)
    }

    static var all: AgentCapabilities {
        AgentCapabilities(canUseTools: true, canProcessVision: true, canGenerateCode: true, canAccessInternet: true)
    }
}
