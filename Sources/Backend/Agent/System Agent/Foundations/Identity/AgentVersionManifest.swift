import Foundation

public enum AgentVersionManifest {
    public static let version = "1.0.0"
    public static let buildNumber = "20240426.1"

    public static var userAgent: String {
        "SystemAgent/\(version) (\(buildNumber))"
    }
}
