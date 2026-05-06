import Foundation
import Combine

@MainActor
public final class SDKToolRuntime: ObservableObject {
    public static let shared = SDKToolRuntime()

    @Published public var executionHistory: [ToolExecutionRecord] = []
    @Published public var activeExecutions: Set<UUID> = []

    private let maxHistorySize = 200
    private let executionQueue = DispatchQueue(label: "com.toolskit.sdk.toolruntime", attributes: .concurrent)

    public struct ToolExecutionRecord: Identifiable {
        public let id: UUID
        public let toolID: UUID
        public let toolName: String
        public let input: [String: String]
        public let output: [String: String]
        public let startTime: Date
        public let endTime: Date
        public let duration: TimeInterval
        public let success: Bool
        public let error: String?
    }

    private init() {}

    // MARK: - Execute

    public func execute(toolID: UUID, input: [String: Any]) async throws -> SDKToolResult {
        guard !activeExecutions.contains(toolID) else {
            throw SDKError.executionFailed(reason: "Tool \(toolID) is already executing")
        }

        activeExecutions.insert(toolID)
        defer { activeExecutions.remove(toolID) }

        let startTime = Date()

        do {
            let result = try await SDKToolManager.shared.execute(toolID: toolID, input: input)
            let endTime = Date()

            let record = ToolExecutionRecord(
                id: UUID(),
                toolID: toolID,
                toolName: SDKToolManager.shared.tools.first(where: { $0.id == toolID })?.name ?? "Unknown",
                input: input.reduce(into: [:]) { $0[$1.key] = String(describing: $1.value) },
                output: result.output.reduce(into: [:]) { $0[$1.key] = String(describing: $1.value) },
                startTime: startTime,
                endTime: endTime,
                duration: result.duration,
                success: result.success,
                error: nil
            )

            appendRecord(record)
            SDKLogStore.shared.log("Tool executed: \(record.toolName) in \(String(format: "%.3f", result.duration))s", source: "SDKToolRuntime", level: .info)

            return result
        } catch {
            let endTime = Date()
            let record = ToolExecutionRecord(
                id: UUID(),
                toolID: toolID,
                toolName: SDKToolManager.shared.tools.first(where: { $0.id == toolID })?.name ?? "Unknown",
                input: input.reduce(into: [:]) { $0[$1.key] = String(describing: $1.value) },
                output: [:],
                startTime: startTime,
                endTime: endTime,
                duration: endTime.timeIntervalSince(startTime),
                success: false,
                error: error.localizedDescription
            )
            appendRecord(record)
            throw error
        }
    }

    // MARK: - Batch Execute

    public func executeBatch(operations: [(toolID: UUID, input: [String: Any])]) async -> [Result<SDKToolResult, Error>] {
        var results: [Result<SDKToolResult, Error>] = []

        for operation in operations {
            do {
                let result = try await execute(toolID: operation.toolID, input: operation.input)
                results.append(.success(result))
            } catch {
                results.append(.failure(error))
            }
        }

        return results
    }

    // MARK: - Metrics

    public func getMetrics() -> ToolRuntimeMetrics {
        let total = executionHistory.count
        let successes = executionHistory.filter { $0.success }.count
        let failures = total - successes
        let avgDuration = executionHistory.isEmpty ? 0 : executionHistory.map(\.duration).reduce(0, +) / Double(total)

        return ToolRuntimeMetrics(
            totalExecutions: total,
            successCount: successes,
            failureCount: failures,
            averageDuration: avgDuration,
            activeCount: activeExecutions.count
        )
    }

    // MARK: - Private

    private func appendRecord(_ record: ToolExecutionRecord) {
        executionHistory.insert(record, at: 0)
        if executionHistory.count > maxHistorySize {
            executionHistory = Array(executionHistory.prefix(maxHistorySize))
        }
    }
}

public struct ToolRuntimeMetrics {
    public let totalExecutions: Int
    public let successCount: Int
    public let failureCount: Int
    public let averageDuration: TimeInterval
    public let activeCount: Int
}
