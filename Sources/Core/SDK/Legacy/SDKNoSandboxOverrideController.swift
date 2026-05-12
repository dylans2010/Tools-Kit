import Foundation

/// Activates sdk.developer.noSandbox mode.
/// Bypasses sandbox ONLY in testing/developer context.
public final class SDKNoSandboxOverrideController {
    public static let shared = SDKNoSandboxOverrideController()

    private init() {}

    public func executeUnrestricted(_ sourceCode: String) async throws {
        Task { @MainActor in
            await SDKLogStore.shared.log("NoSandboxOverride: ACTIVATING DIRECT WORKSPACE ACCESS.", source: "SDKNoSandboxOverrideController", level: .warning)
        }

        // This activates the high-power pipeline
        try await SDKSandboxEngine.shared.executeUnrestricted(sourceCode: sourceCode)
    }

    public func isNoSandboxEnabled() -> Bool {
        return SDKRuntimeEngine.shared.isNoSandboxModeEnabled
    }
}
