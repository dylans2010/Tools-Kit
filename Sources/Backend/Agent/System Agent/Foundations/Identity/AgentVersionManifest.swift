import Foundation

struct AgentVersionManifest: Codable {
    var version: String
    var builtAt: Date

    init(version: String, builtAt: Date = Date()) {
        self.version = version
        self.builtAt = builtAt
    }
}
