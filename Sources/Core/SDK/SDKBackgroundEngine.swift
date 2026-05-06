import Foundation
import Combine
import BackgroundTasks

public struct SDKHealthReport {
    public var connectorReachability: Bool
    public var pluginSandboxStatus: Bool
    public var coreDataHealth: Bool
    public var lastCheck: Date
}

@MainActor
public final class SDKBackgroundEngine: ObservableObject {
    public static let shared = SDKBackgroundEngine()

    @Published public var systemHealth = SDKHealthReport(connectorReachability: true, pluginSandboxStatus: true, coreDataHealth: true, lastCheck: Date())

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
            // Check connectors
            let connectorsHealthy = await checkConnectors()

            // Check plugins via sandbox engine
            let pluginsHealthy = SDKSandboxEngine.shared.isHealthy

            // Check persistent store health
            let storageHealthy = SDKProjectManager.shared.currentProject != nil

            systemHealth = SDKHealthReport(
                connectorReachability: connectorsHealthy,
                pluginSandboxStatus: pluginsHealthy,
                coreDataHealth: storageHealthy,
                lastCheck: Date()
            )

            SDKLogStore.shared.log("Health check performed", source: "SDKBackgroundEngine", level: .info)
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

    // MARK: - Background Tasks

    public func scheduleSync() {
        let request = BGAppRefreshTaskRequest(identifier: "com.toolskit.sdk.sync")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }

    public func handleSync(task: BGAppRefreshTask) {
        scheduleSync()

        task.expirationHandler = {
            // Cancel operations
        }

        Task {
            do {
                try await SDKConnectorManager.shared.syncAll()
                task.setTaskCompleted(success: true)
                SDKLogStore.shared.log("Background sync completed", source: "SDKBackgroundEngine", level: .info)
            } catch {
                task.setTaskCompleted(success: false)
                SDKLogStore.shared.log("Background sync failed: \(error.localizedDescription)", source: "SDKBackgroundEngine", level: .error)
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
            } catch {
                if item.retryCount < item.maxRetries {
                    let delay = pow(2.0, Double(item.retryCount + 1))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    retryQueue.append((operation: item.operation, retryCount: item.retryCount + 1, maxRetries: item.maxRetries))
                    processRetryQueue()
                } else {
                    SDKLogStore.shared.log("Operation failed after \(item.maxRetries) retries", source: "SDKBackgroundEngine", level: .error)
                }
            }
        }
    }
}
