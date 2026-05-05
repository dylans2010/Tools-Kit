import Foundation

/// Bridges SDK projects to Plugin/Connector runtimes.
/// Injects WorkspaceAPI and enforces permissions.
public final class SDKExecutionBridge {
    public static let shared = SDKExecutionBridge()

    private let sandboxEngine = SDKSandboxEngine.shared

    private init() {}

    public func execute(sourceCode: String, context: SDKExecutionContext) async throws {
        // Bridge logic: Convert SDK execution request to a sandboxed (or unrestricted) call

        if context.noSandbox {
            // High-power unrestricted execution
            try await sandboxEngine.executeUnrestricted(sourceCode: sourceCode)
        } else {
            // Standard sandboxed execution
            try await sandboxEngine.executeSandboxed(sourceCode: sourceCode)
        }
    }

    /// Converts an SDK project to a PluginDefinition for deployment
    public func deployToPlugin(project: SDKProject) -> PluginDefinition {
        return PluginDefinition(
            id: UUID(),
            name: project.name,
            description: "Deployed from SDK",
            author: "SDK Developer",
            version: "1.0.0",
            icon: "hammer.fill",
            identifier: "com.toolskit.sdk.\(project.name.lowercased().replacingOccurrences(of: " ", with: "."))",
            isEnabled: true,
            isInstalled: true,
            installedAt: Date(),
            capabilities: project.requiredScopes.compactMap { PluginCapability(rawValue: $0) },
            actions: [.workspaceEvent], // Default subscription
            sourceCode: project.sourceCode
        )
    }
}
