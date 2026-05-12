import Foundation

enum AgentVersionManifest: Sendable {
    static let version = "1.0.0"
    static let buildNumber = "20240426.1"

    static var userAgent: String {
        "SystemAgent/\(version) (\(buildNumber))"
    }
}
