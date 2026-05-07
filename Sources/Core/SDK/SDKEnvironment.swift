import Foundation

/// Configuration and environment settings for the WorkspaceSDK.
public struct SDKEnvironment {
    public enum Mode {
        case development
        case production
        case testing
    }

    public let mode: Mode
    public let version: String
    public let isSandboxEnabled: Bool

    public static let current = SDKEnvironment(
        mode: .development,
        version: "1.0.0",
        isSandboxEnabled: true
    )
}
