import Foundation
import Combine

/// Protocol for plugin/app lifecycle management.
@MainActor
public protocol SDKAppLifecycle {
    var appId: UUID { get }
    var appName: String { get }
    func onInit() async throws
    func onStart() async throws
    func onStop() async throws
}

/// Protocol for the plugin runtime engine.
@MainActor
public protocol PluginRuntimeProtocol {
    func register(_ app: SDKAppDefinition) throws
    func start(appId: UUID) async throws
    func stop(appId: UUID) async throws
}

/// Runtime engine for loading and executing SDK apps and plugins.
/// Manages app lifecycle with isolated execution and permission enforcement.
@MainActor
public final class PluginRuntimeEngine: PluginRuntimeProtocol, ObservableObject {
    nonisolated(unsafe) public static let shared = PluginRuntimeEngine()

    @Published public var loadedApps: [SDKAppDefinition] = []
    @Published public var runningApps: Set<UUID> = []

    private let persistenceKey = "sdk_runtime_apps"
    private var lifecycleHandlers: [UUID: SDKAppLifecycle] = [:]

    private init() {}

    public func initialize() {
        loadApps()
    }

    // MARK: - Registration

    public func register(_ app: SDKAppDefinition) throws {
        guard !loadedApps.contains(where: { $0.id == app.id }) else {
            throw SDKError.validationError(reason: "App '\(app.name)' is already registered")
        }

        guard AuthorizationManager.shared.canUseScopes(app.requiredScopes) || app.requiredScopes.isEmpty else {
            throw SDKError.permissionDenied(scope: app.requiredScopes.joined(separator: ","))
        }

        // Validate permissions
        for permission in app.permissions {
            guard SDKPermissionManager.shared.isScopeAuthorized(permission) else {
                throw SDKError.permissionDenied(scope: permission)
            }
        }

        loadedApps.append(app)
        saveApps()

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.apps",
            name: "app.registered",
            data: ["appId": app.id.uuidString, "name": app.name]
        ))

        Task {
            await SDKLogStore.shared.log("App registered: \(app.name) v\(app.version)", source: "PluginRuntime", level: .info)
        }
    }

    // MARK: - Lifecycle

    public func start(appId: UUID) async throws {
        guard let index = loadedApps.firstIndex(where: { $0.id == appId }) else {
            throw SDKError.executionFailed(reason: "App not found")
        }
        guard !runningApps.contains(appId) else { return }

        guard AuthorizationManager.shared.canUseScopes(loadedApps[index].requiredScopes) || loadedApps[index].requiredScopes.isEmpty else {
            loadedApps[index].isEnabled = false
            saveApps()
            throw SDKError.permissionDenied(scope: loadedApps[index].requiredScopes.joined(separator: ","))
        }

        // Check sandbox permissions
        if loadedApps[index].isSandboxed {
            for permission in loadedApps[index].permissions {
                guard SDKPermissionManager.shared.isScopeAuthorized(permission) else {
                    throw SDKError.permissionDenied(scope: permission)
                }
            }
        }

        if let handler = lifecycleHandlers[appId] {
            try await handler.onStart()
        }

        loadedApps[index].isEnabled = true
        runningApps.insert(appId)
        saveApps()

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.apps",
            name: "app.started",
            data: ["appId": appId.uuidString, "name": loadedApps[index].name]
        ))

        await SDKLogStore.shared.log("App started: \(loadedApps[index].name)", source: "PluginRuntime", level: .info)
    }

    public func stop(appId: UUID) async throws {
        guard let index = loadedApps.firstIndex(where: { $0.id == appId }) else {
            throw SDKError.executionFailed(reason: "App not found")
        }

        if let handler = lifecycleHandlers[appId] {
            try await handler.onStop()
        }

        loadedApps[index].isEnabled = false
        runningApps.remove(appId)
        saveApps()

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.apps",
            name: "app.stopped",
            data: ["appId": appId.uuidString, "name": loadedApps[index].name]
        ))

        await SDKLogStore.shared.log("App stopped: \(loadedApps[index].name)", source: "PluginRuntime", level: .info)
    }

    public func stopAll() {
        runningApps.removeAll()
        for index in loadedApps.indices {
            loadedApps[index].isEnabled = false
        }
        saveApps()
    }

    // MARK: - Lifecycle Handler Registration

    public func registerLifecycleHandler(_ handler: SDKAppLifecycle) {
        lifecycleHandlers[handler.appId] = handler
    }

    // MARK: - Unregister

    public func unregister(appId: UUID) {
        runningApps.remove(appId)
        lifecycleHandlers.removeValue(forKey: appId)
        loadedApps.removeAll { $0.id == appId }
        saveApps()

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.apps",
            name: "app.unregistered",
            data: ["appId": appId.uuidString]
        ))
    }

    // MARK: - Query

    public func getApp(_ id: UUID) -> SDKAppDefinition? {
        return loadedApps.first { $0.id == id }
    }

    public func isRunning(_ id: UUID) -> Bool {
        return runningApps.contains(id)
    }

    // MARK: - Persistence

    private func saveApps() {
        if let data = try? JSONEncoder().encode(loadedApps) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func loadApps() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let decoded = try? JSONDecoder().decode([SDKAppDefinition].self, from: data) {
            loadedApps = decoded
        }
    }
}
