import Foundation

/// WorkspaceSDK: The primary entry point for developers.
/// Exposes all feature modules and core services of the Workspace platform.
@MainActor
public final class WorkspaceSDK {
    public static let shared = WorkspaceSDK()

    // Foundation
    public let kernel = WorkspaceSDKKernel.shared
    public let environment = SDKEnvironment.current

    // Feature Modules
    public let mail = SDKMail.shared
    public let notebooks = SDKNotebooks.shared
    public let meet = SDKMeet.shared
    public let articles = SDKArticles.shared

    // Core Services
    public let storage = SDKDataStore.shared
    public let events = SDKEventBus.shared
    public let plugins = PluginRuntime.shared
    public let permissions = SDKPermissionManager.shared
    public let router = SDKRouter.shared

    private init() {
        // Trigger initialization of modules
        _ = mail
        _ = notebooks
        _ = meet
        _ = articles
    }

    /// Bootstraps the entire SDK environment.
    public func bootstrap() async {
        await kernel.bootstrap()
    }
}
