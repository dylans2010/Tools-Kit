import Foundation
import Combine

/// WorkspaceSDK — The unified public interface for the entire SDK platform.
@MainActor
public final class WorkspaceSDK: ObservableObject {
    public static let shared = WorkspaceSDK()

    // MARK: - Public Module Access

    public let mail = SDKMailService.shared
    public let notebooks = SDKNotebookService.shared
    public let meet = SDKMeetService.shared
    public let articles = SDKArticleService.shared
    public let plugins = PluginRuntimeEngine.shared
    public let storage = SDKDataStore.shared
    public let events = SDKEventBus.shared
    public let router = SDKRouter.shared
    public let security = SDKPermissionManager.shared
    public let kernel = WorkspaceSDKKernel.shared
    public let environment = SDKEnvironment.shared
    public let services = ServiceContainer.shared

    @Published public private(set) var isInitialized = false
    @Published public private(set) var version: String = "2.0.0"

    private init() {}

    public func initialize() async {
        guard !isInitialized else { return }
        await kernel.boot()
        isInitialized = kernel.isReady
    }

    public func shutdown() async {
        await kernel.shutdown()
        isInitialized = false
    }

    public func api(_ path: String, method: SDKRoute.Method = .get, parameters: [String: String] = [:]) async throws -> SDKResponse {
        let request = SDKRequest(path: path, method: method, parameters: parameters)
        return try await router.handle(request)
    }

    public func apiRoutes() -> [SDKRoute] {
        return router.routes()
    }
}
