import Foundation

public struct AgentCapabilities: Codable, Equatable {
    public var canUseTools: Bool
    public var canProcessVision: Bool
    public var canGenerateCode: Bool
    public var canAccessInternet: Bool

    public static var none: AgentCapabilities {
        AgentCapabilities(canUseTools: false, canProcessVision: false, canGenerateCode: false, canAccessInternet: false)
    }

    public static var all: AgentCapabilities {
        AgentCapabilities(canUseTools: true, canProcessVision: true, canGenerateCode: true, canAccessInternet: true)
    }
}
