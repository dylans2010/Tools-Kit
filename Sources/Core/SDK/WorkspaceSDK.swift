import Foundation
import Combine

/// WorkspaceSDK — The unified public interface for the entire SDK platform.
///
/// Usage:
/// ```swift
/// let sdk = WorkspaceSDK.shared
///
/// // Mail
/// try await sdk.mail.send(to: "user@example.com", subject: "Hello", body: "World")
/// let messages = sdk.mail.listMessages()
///
/// // Notebooks
/// let notebook = try sdk.notebooks.createNotebook(title: "My Notes")
/// try sdk.notebooks.addPage(to: notebook.id, title: "Page 1", content: "Content")
///
/// // Meet
/// let session = try sdk.meet.createSession(title: "Standup")
/// try await sdk.meet.startSession(id: session.id)
///
/// // Articles
/// let article = try sdk.articles.createArticle(title: "Post", content: "Body")
///
/// // Events
/// sdk.events.publish(SDKBusEvent(channel: "custom", name: "hello", data: [:]))
/// let sub = sdk.events.subscribe(channel: "custom") { event in print(event) }
///
/// // Plugins
/// try sdk.plugins.register(appDef)
/// try await sdk.plugins.start(appId: appDef.id)
///
/// // Storage
/// try sdk.storage.save(myModel)
/// let items = sdk.storage.fetchAll(MyModel.self)
/// ```
@MainActor
public final class WorkspaceSDK: ObservableObject {
    nonisolated(unsafe) public static let shared = WorkspaceSDK()

    // MARK: - Public Module Access

    /// Mail service — send, read, search, and manage email messages.
    public let mail = SDKMailService.shared

    /// Notebooks service — create, edit, and version-track notebooks and pages.
    public let notebooks = SDKNotebookService.shared

    /// Meet service — create sessions, manage presence, take meeting notes.
    public let meet = SDKMeetService.shared

    /// Articles service — create, publish, parse, and search articles.
    public let articles = SDKArticleService.shared

    /// Plugin/app runtime — register, start, stop, and manage SDK apps.
    public let plugins = PluginRuntimeEngine.shared

    /// Unified data store — offline-first persistence for any SDKModel.
    public let storage = SDKDataStore.shared

    /// Event bus — publish/subscribe real-time events across modules.
    public let events = SDKEventBus.shared

    /// Internal API router — register and handle on-device API endpoints.
    public let router = SDKRouter.shared

    /// Security — permission management and sandbox enforcement.
    public let security = SDKSecurityPolicy.shared

    /// Kernel — lifecycle and health management.
    public let kernel = WorkspaceSDKKernel.shared

    /// Environment — SDK configuration and feature flags.
    public let environment = SDKEnvironment.shared

    /// Service container — dependency injection and service resolution.
    public let services = ServiceContainer.shared

    // MARK: - State

    @Published public private(set) var isInitialized = false
    @Published public private(set) var version: String = "2.0.0"

    private var cancellables = Set<AnyCancellable>()

    private init() {}

    // MARK: - Initialization

    /// Boot the entire SDK. Call this once at app launch.
    public func initialize() async {
        guard !isInitialized else { return }

        await kernel.boot()
        isInitialized = kernel.isReady
        version = environment.configuration.sdkVersion

        // Bridge legacy SDK
        ToolsKitSDK.shared.isInitialized = true
    }

    // MARK: - Shutdown

    /// Gracefully shut down all SDK services.
    public func shutdown() async {
        await kernel.shutdown()
        isInitialized = false
    }

    // MARK: - Health

    /// Get a full health report of the SDK.
    public func healthCheck() -> KernelHealth {
        return kernel.healthCheck()
    }

    // MARK: - Quick API Access

    /// Execute an API request through the internal router.
    public func api(_ path: String, method: SDKRoute.Method = .get, parameters: [String: String] = [:]) async throws -> SDKResponse {
        let request = SDKRequest(path: path, method: method, parameters: parameters)
        return try await router.handle(request)
    }

    /// List all registered API routes.
    public func apiRoutes() -> [SDKRoute] {
        return router.routes()
    }

    // MARK: - Event Shortcuts

    /// Publish an event to a channel.
    public func emit(channel: String, name: String, data: [String: String] = [:]) {
        events.publish(SDKBusEvent(channel: channel, name: name, data: data))
    }

    /// Subscribe to events on a channel.
    public func on(channel: String, handler: @escaping (SDKBusEvent) -> Void) -> AnyCancellable {
        return events.subscribe(channel: channel, handler: handler)
    }

    // MARK: - Data Shortcuts

    /// Save any SDKModel to persistent storage.
    public func save<T: SDKModel>(_ model: T) throws {
        try storage.save(model)
    }

    /// Fetch all models of a given type.
    public func fetchAll<T: SDKModel>(_ type: T.Type) -> [T] {
        return storage.fetchAll(type)
    }

    /// Query models with a predicate.
    public func query<T: SDKModel>(_ type: T.Type, where predicate: (T) -> Bool) -> [T] {
        return storage.query(type, predicate: predicate)
    }

    // MARK: - Legacy Bridge

    /// Access the legacy ToolsKitSDK for backward compatibility.
    public var legacy: ToolsKitSDK { ToolsKitSDK.shared }
}
