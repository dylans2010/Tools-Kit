import Foundation
import Combine

/// The central bootstrap and lifecycle manager for the entire WorkspaceSDK.
/// Initializes all services, manages lifecycle, and provides the global access point.
@MainActor
public final class WorkspaceSDKKernel: ObservableObject {
    public static let shared = WorkspaceSDKKernel()

    @Published public private(set) var state: KernelState = .idle
    @Published public private(set) var bootTime: Date?
    @Published public private(set) var uptimeSeconds: TimeInterval = 0

    private var uptimeTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    public enum KernelState: String, CaseIterable, Sendable {
        case idle, booting, ready, error, shuttingDown
    }

    private init() {}

    // MARK: - Bootstrap

    public func boot() async {
        guard state == .idle || state == .error else { return }
        state = .booting

        await SDKLogStore.shared.log("WorkspaceSDKKernel booting...", source: "Kernel", level: .info)

        do {
            try await bootSequence()
            state = .ready
            bootTime = Date()
            startUptimeTimer()
            await SDKLogStore.shared.log("WorkspaceSDKKernel ready", source: "Kernel", level: .info)
            SDKEventBus.shared.publish(SDKBusEvent(channel: "sdk.lifecycle", name: "kernel.ready", data: [:]))
        } catch {
            state = .error
            await SDKLogStore.shared.log("Kernel boot failed: \(error.localizedDescription)", source: "Kernel", level: .error)
        }
    }

    private func bootSequence() async throws {
        // 1. Initialize environment
        SDKEnvironment.shared.load()

        // 2. Initialize service container
        ServiceContainer.shared.registerDefaults()

        // 3. Initialize data store
        SDKDataStore.shared.initialize()

        // 4. Initialize event bus
        SDKEventBus.shared.start()

        // 5. Initialize router
        SDKRouter.shared.registerDefaultRoutes()

        // 6. Initialize permission manager
        _ = SDKPermissionManager.shared

        // 7. Initialize plugin runtime
        PluginRuntimeEngine.shared.initialize()

        // 8. Boot feature modules
        await bootFeatureModules()
    }

    private func bootFeatureModules() async {
        SDKMailService.shared.initialize()
        SDKNotebookService.shared.initialize()
        SDKMeetService.shared.initialize()
        SDKArticleService.shared.initialize()
    }

    // MARK: - Shutdown

    public func shutdown() async {
        state = .shuttingDown
        uptimeTimer?.invalidate()
        uptimeTimer = nil

        SDKEventBus.shared.publish(SDKBusEvent(channel: "sdk.lifecycle", name: "kernel.shutdown", data: [:]))
        PluginRuntimeEngine.shared.stopAll()
        SDKDataStore.shared.flush()
        SDKEventBus.shared.stop()

        state = .idle
        bootTime = nil
        uptimeSeconds = 0
        await SDKLogStore.shared.log("WorkspaceSDKKernel shutdown complete", source: "Kernel", level: .info)
    }

    // MARK: - Health

    public var isReady: Bool { state == .ready }

    public func healthCheck() -> KernelHealth {
        let services = ServiceContainer.shared.registeredServiceNames()
        let pluginCount = PluginRuntimeEngine.shared.loadedApps.count
        let dataStoreOk = SDKDataStore.shared.isInitialized
        let eventBusOk = SDKEventBus.shared.isRunning

        return KernelHealth(
            state: state,
            uptime: uptimeSeconds,
            registeredServices: services.count,
            loadedPlugins: pluginCount,
            dataStoreHealthy: dataStoreOk,
            eventBusHealthy: eventBusOk
        )
    }

    private func startUptimeTimer() {
        uptimeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let boot = self.bootTime else { return }
                self.uptimeSeconds = Date().timeIntervalSince(boot)
            }
        }
    }
}

// MARK: - Kernel Health

public struct KernelHealth: Codable, Sendable {
    public let state: WorkspaceSDKKernel.KernelState
    public let uptime: TimeInterval
    public let registeredServices: Int
    public let loadedPlugins: Int
    public let dataStoreHealthy: Bool
    public let eventBusHealthy: Bool

    public var isHealthy: Bool {
        state == .ready && dataStoreHealthy && eventBusHealthy
    }
}

extension WorkspaceSDKKernel.KernelState: Codable {}
