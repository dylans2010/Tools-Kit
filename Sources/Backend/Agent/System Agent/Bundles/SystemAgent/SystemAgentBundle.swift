import Foundation

struct SystemAgentBundle: Codable {
    var id: String
    var profile: SystemAgentCapabilityProfile
    var manifest: SystemAgentToolManifest

    init(id: String = "system.agent", profile: SystemAgentCapabilityProfile = .init(), manifest: SystemAgentToolManifest = .init()) {
        self.id = id
        self.profile = profile
        self.manifest = manifest
    }
}
