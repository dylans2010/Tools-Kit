import Foundation
import Combine

/// WorkspaceSDKKernel: The foundation of the WorkspaceSDK.
/// Bootstraps services, manages lifecycle, and provides the internal global access point.
@MainActor
public final class WorkspaceSDKKernel: ObservableObject {
    public static let shared = WorkspaceSDKKernel()

    @Published public private(set) var isInitialized = false
    public let context: SDKContext
    public let environment: SDKEnvironment

    private init(context: SDKContext = .default, environment: SDKEnvironment = .current) {
        self.context = context
        self.environment = environment
    }

    public func bootstrap() async {
        guard !isInitialized else { return }

        await SDKLogStore.shared.log("WorkspaceSDKKernel bootstrapping...", source: "Kernel", level: .info)

        // Initialize Core Services (to be implemented in following steps)
        // 1. Dependency Injection
        // 2. Data Store
        // 3. Router
        // 4. Event Bus

        isInitialized = true
        await SDKLogStore.shared.log("WorkspaceSDKKernel initialized successfully.", source: "Kernel", level: .info)
    }

    public func shutdown() async {
        await SDKLogStore.shared.log("WorkspaceSDKKernel shutting down...", source: "Kernel", level: .info)
        isInitialized = false
    }
}
