import Foundation
import Combine
import BackgroundTasks

public struct SDKBackgroundHealthReport: Sendable {
    public var connectorReachability: Bool
    public var pluginSandboxStatus: Bool
    public var coreDataHealth: Bool
    public var lastCheck: Date
    public var details: [String: Bool]
}

@MainActor
public final class SDKBackgroundEngine: ObservableObject {
    public static let shared = SDKBackgroundEngine()

    @Published public var systemHealth = SDKBackgroundHealthReport(connectorReachability: true, pluginSandboxStatus: true, coreDataHealth: true, lastCheck: Date(), details: [:])

    private let syncQueue = DispatchQueue(label: "com.toolskit.sdk.sync", attributes: .concurrent)
    private var healthTimer: AnyCancellable?
    private var retryQueue: [(operation: () async throws -> Void, retryCount: Int, maxRetries: Int)] = []

    private init() {
        startHealthCheckLoop()
    }

    public func startHealthCheckLoop() {
        healthTimer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performHealthCheck()
            }
    }

    private func performHealthCheck() {
        Task {
            let connectorsHealthy = await checkConnectors()
            let pluginsHealthy = checkPlugins()
            let storageHealthy = checkStorage()

            var details: [String: Bool] = [
                "connectors": connectorsHealthy,
                "plugins": pluginsHealthy,
                "storage": storageHealthy
            ]

            for connector in SDKConnectorManager.shared.connectors {
                let reachable: Bool
                do {
                    reachable = try await connector.testConnection()
                } catch {
                    reachable = false
                }
                details["connector.\(connector.name)"] = reachable
            }

            systemHealth = SDKBackgroundHealthReport(
                connectorReachability: connectorsHealthy,
                pluginSandboxStatus: pluginsHealthy,
                coreDataHealth: storageHealthy,
                lastCheck: Date(),
                details: details
            )

            SDKLogStore.shared.log("Health check: connectors=\(connectorsHealthy) plugins=\(pluginsHealthy) storage=\(storageHealthy)", source: "SDKBackgroundEngine", level: LogLevel.info)
        }
    }

    private func checkConnectors() async -> Bool {
        for connector in SDKConnectorManager.shared.connectors {
            do {
                _ = try await connector.testConnection()
            } catch {
                return false
            }
        }
        return true
    }

    private func checkPlugins() -> Bool {
        let plugins = SDKPluginManager.shared.plugins
        for plugin in plugins where plugin.isEnabled {
            if plugin.tools.isEmpty && plugin.automationHooks.isEmpty {
                continue
            }
        }
        return true
    }

    private func checkStorage() -> Bool {
        let context = SDKCoreDataStack.shared.context
        return context.persistentStoreCoordinator?.persistentStores.isEmpty == false
    }

    // MARK: - Background Tasks

    public func scheduleSync() {
        let request = BGAppRefreshTaskRequest(identifier: "com.toolskit.sdk.sync")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            SDKLogStore.shared.log("Background sync scheduled", source: "SDKBackgroundEngine", level: LogLevel.info)
        } catch {
            SDKLogStore.shared.log("Could not schedule background sync: \(error.localizedDescription)", source: "SDKBackgroundEngine", level: LogLevel.error)
        }
    }

    public func handleSync(task: BGAppRefreshTask) {
        scheduleSync()

        task.expirationHandler = { [weak self] in
            SDKLogStore.shared.log("Background sync expired", source: "SDKBackgroundEngine", level: LogLevel.warning)
            self?.retryQueue.removeAll()
        }

        Task {
            do {
                try await SDKConnectorManager.shared.syncAll()
                task.setTaskCompleted(success: true)
                SDKLogStore.shared.log("Background sync completed", source: "SDKBackgroundEngine", level: LogLevel.info)
            } catch {
                task.setTaskCompleted(success: false)
                SDKLogStore.shared.log("Background sync failed: \(error.localizedDescription)", source: "SDKBackgroundEngine", level: LogLevel.error)
            }
        }
    }

    // MARK: - Retry Logic

    public func enqueueRetry(operation: @escaping () async throws -> Void, maxRetries: Int = 3) {
        retryQueue.append((operation: operation, retryCount: 0, maxRetries: maxRetries))
        processRetryQueue()
    }

    private func processRetryQueue() {
        guard !retryQueue.isEmpty else { return }

        let item = retryQueue.removeFirst()
        Task {
            do {
                try await item.operation()
                SDKLogStore.shared.log("Retry operation succeeded", source: "SDKBackgroundEngine", level: LogLevel.info)
            } catch {
                if item.retryCount < item.maxRetries {
                    let delay = pow(2.0, Double(item.retryCount + 1))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    retryQueue.append((operation: item.operation, retryCount: item.retryCount + 1, maxRetries: item.maxRetries))
                    processRetryQueue()
                } else {
                    SDKLogStore.shared.log("Operation failed after \(item.maxRetries) retries: \(error.localizedDescription)", source: "SDKBackgroundEngine", level: LogLevel.error)
                }
            }
        }
    }
}
