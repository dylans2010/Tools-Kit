import Foundation
import Combine

@MainActor
public final class SDKExecutionEngine: ObservableObject {
    public static let shared = SDKExecutionEngine()

    @Published public var activeExecutions: [UUID: ExecutionState] = [:]
    @Published public var executionHistory: [ExecutionRecord] = []

    private let executionQueue = DispatchQueue(label: "com.toolskit.sdk.execution", attributes: .concurrent)
    private let maxConcurrentExecutions = 10
    private let maxHistorySize = 500

    public struct ExecutionState {
        public let id: UUID
        public let action: SDKAction
        public let startTime: Date
        public var status: Status

        public enum Status {
            case running, completed, failed(Error)
        }
    }

    public struct ExecutionRecord: Identifiable {
        public let id: UUID
        public let action: SDKAction
        public let startTime: Date
        public let endTime: Date
        public let duration: TimeInterval
        public let success: Bool
        public let error: String?
    }

    private init() {}

    public func execute(action: SDKAction, context: SDKExecutionContext) async throws {
        let executionID = UUID()

        guard activeExecutions.count < maxConcurrentExecutions else {
            throw SDKError.executionFailed(reason: "Maximum concurrent executions reached (\(maxConcurrentExecutions))")
        }

        activeExecutions[executionID] = ExecutionState(id: executionID, action: action, startTime: Date(), status: .running)

        let startTime = Date()

        do {
            try await SDKExecutionKernel.shared.execute(action: action, context: context)
            activeExecutions[executionID]?.status = .completed
            recordExecution(id: executionID, action: action, startTime: startTime, success: true, error: nil)
        } catch {
            activeExecutions[executionID]?.status = .failed(error)
            recordExecution(id: executionID, action: action, startTime: startTime, success: false, error: error.localizedDescription)
            activeExecutions.removeValue(forKey: executionID)
            throw error
        }

        activeExecutions.removeValue(forKey: executionID)
    }

    public func executeWithRetry(action: SDKAction, context: SDKExecutionContext, maxRetries: Int = 3) async throws {
        var lastError: Error?

        for attempt in 0...maxRetries {
            do {
                try await execute(action: action, context: context)
                return
            } catch {
                lastError = error
                if attempt < maxRetries {
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    SDKLogStore.shared.log("Retrying action (attempt \(attempt + 1)/\(maxRetries))", source: "SDKExecutionEngine", level: LogLevel.warning)
                }
            }
        }

        throw lastError ?? SDKError.executionFailed(reason: "Unknown error after retries")
    }

    public func cancelExecution(id: UUID) {
        activeExecutions.removeValue(forKey: id)
        SDKLogStore.shared.log("Execution cancelled: \(id)", source: "SDKExecutionEngine", level: LogLevel.info)
    }

    public func getMetrics() -> ExecutionMetrics {
        let totalExecutions = executionHistory.count
        let successCount = executionHistory.filter { $0.success }.count
        let failureCount = totalExecutions - successCount
        let avgDuration = executionHistory.isEmpty ? 0 : executionHistory.map(\.duration).reduce(0, +) / Double(totalExecutions)

        return ExecutionMetrics(
            totalExecutions: totalExecutions,
            successCount: successCount,
            failureCount: failureCount,
            averageDuration: avgDuration,
            activeCount: activeExecutions.count
        )
    }

    private func recordExecution(id: UUID, action: SDKAction, startTime: Date, success: Bool, error: String?) {
        let endTime = Date()
        let record = ExecutionRecord(
            id: id,
            action: action,
            startTime: startTime,
            endTime: endTime,
            duration: endTime.timeIntervalSince(startTime),
            success: success,
            error: error
        )
        executionHistory.insert(record, at: 0)
        if executionHistory.count > maxHistorySize {
            executionHistory = Array(executionHistory.prefix(maxHistorySize))
        }
    }
}

public struct ExecutionMetrics {
    public let totalExecutions: Int
    public let successCount: Int
    public let failureCount: Int
    public let averageDuration: TimeInterval
    public let activeCount: Int

    public var successRate: Double {
        guard totalExecutions > 0 else { return 0 }
        return Double(successCount) / Double(totalExecutions)
    }
}
