import Foundation

struct JulesAgentBundle: Codable {
    var id: String
    var profile: JulesAgentCapabilityProfile
    var manifest: JulesAgentToolManifest

    init(id: String = "agent.jules", profile: JulesAgentCapabilityProfile = .init(), manifest: JulesAgentToolManifest = .init()) {
        self.id = id
        self.profile = profile
        self.manifest = manifest
    }
}
