import Foundation
import BackgroundTasks

public struct SDKHealthReport: Codable {
    public let overallStatus: HealthStatus
    public let lastCheckTime: Date
    public let connectorReachability: [UUID: Bool]
    public let pluginSandboxStatus: [UUID: Bool]
    public let coreDataStoreHealth: Bool
}

@MainActor
public final class SDKBackgroundEngine: ObservableObject {
    public static let shared = SDKBackgroundEngine()

    @Published public var systemHealth: SDKHealthReport = SDKHealthReport(
        overallStatus: .unknown,
        lastCheckTime: Date(),
        connectorReachability: [:],
        pluginSandboxStatus: [:],
        coreDataStoreHealth: true
    )

    private let syncQueue = DispatchQueue(label: "com.toolskit.sdk.sync", attributes: .concurrent)
    private var retryQueue: [(operation: () async throws -> Void, retryCount: Int, maxRetries: Int)] = []
    private var healthTimer: Timer?

    private init() {
        registerBackgroundTasks()
        startHealthCheckLoop()
    }

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.toolskit.sdk.sync", using: nil) { task in
            self.handleSync(task: task as! BGAppRefreshTask)
        }
    }

    public func scheduleSync() {
        let request = BGAppRefreshTaskRequest(identifier: "com.toolskit.sdk.sync")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 mins
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            SDKLogStore.shared.log("Failed to schedule sync: \(error.localizedDescription)", source: "SDKBackgroundEngine", level: .error)
        }
    }

    public func handleSync(task: BGAppRefreshTask) {
        scheduleSync()

        task.expirationHandler = {
            // Cancel operations
        }

        Task {
            let group = DispatchGroup()
            for connector in SDKConnectorManager.shared.connectors {
                group.enter()
                syncQueue.async {
                    Task {
                        do {
                            try await connector.sync()
                        } catch {
                            SDKLogStore.shared.log("Sync failed for \(connector.name): \(error.localizedDescription)", source: "SDKBackgroundEngine", level: .error)
                        }
                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) {
                task.setTaskCompleted(success: true)
            }
        }
    }

    private func startHealthCheckLoop() {
        healthTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                await self.performHealthCheck()
            }
        }
    }

    private func performHealthCheck() async {
        var reachability: [UUID: Bool] = [:]
        for connector in SDKConnectorManager.shared.connectors {
            reachability[connector.id] = try? await connector.testConnection()
        }

        let report = SDKHealthReport(
            overallStatus: .healthy, // Simplified logic
            lastCheckTime: Date(),
            connectorReachability: reachability,
            pluginSandboxStatus: [:],
            coreDataStoreHealth: true
        )

        self.systemHealth = report
        SDKProjectManager.shared.updateHealth()
    }

    public func enqueueRetry(operation: @escaping () async throws -> Void, maxRetries: Int = 3) {
        retryQueue.append((operation, 0, maxRetries))
        processRetryQueue()
    }

    private func processRetryQueue() {
        guard !retryQueue.isEmpty else { return }

        let (operation, count, max) = retryQueue.removeFirst()

        Task {
            do {
                try await operation()
            } catch {
                if count < max {
                    let delay = pow(2.0, Double(count + 1))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    self.retryQueue.append((operation, count + 1, max))
                    self.processRetryQueue()
                } else {
                    SDKLogStore.shared.log("Max retries reached for operation", source: "SDKBackgroundEngine", level: .error)
                }
            }
        }
    }
}
