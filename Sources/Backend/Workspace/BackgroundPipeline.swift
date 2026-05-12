import Foundation
import os.log

/// Orchestrates background tasks for AI processing, indexing, and rendering with priority support and retries.
final class BackgroundPipeline {
    static let shared = BackgroundPipeline()
    private let queue = DispatchQueue(label: "com.workspace.pipeline", qos: .utility, attributes: .concurrent)
    private let logger = Logger(subsystem: "com.workspace", category: "Pipeline")

    enum TaskPriority: Int, Sendable {
        case low = 0
        case medium = 1
        case high = 2
        case critical = 3
    }

    struct PipelineTask: @unchecked Sendable {
        let id: UUID = UUID()
        let name: String
        let priority: TaskPriority
        let retryCount: Int
        let action: () async throws -> Void
    }

    private init() {}

    func enqueue(
        taskName: String,
        priority: TaskPriority = .medium,
        maxRetries: Int = 3,
        action: @escaping () async throws -> Void
    ) {
        let task = PipelineTask(name: taskName, priority: priority, retryCount: maxRetries, action: action)

        queue.async(group: nil, qos: qos(for: priority), flags: []) {
            Task {
                await self.execute(task: task, attempt: 1)
            }
        }
    }

    private func execute(task: PipelineTask, attempt: Int) async {
        do {
            self.logger.info("Starting task: \(task.name) (Attempt \(attempt))")
            try await task.action()
            self.logger.info("Completed task: \(task.name)")
        } catch {
            self.logger.error("Task \(task.name) failed: \(error.localizedDescription)")

            if attempt < task.retryCount {
                let delay = Double(attempt) * 2.0 // Exponential backoff simulation
                self.logger.info("Retrying task \(task.name) in \(delay) seconds...")
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await execute(task: task, attempt: attempt + 1)
            } else {
                self.logger.fault("Task \(task.name) permanently failed after \(attempt) attempts.")
            }
        }
    }

    private func qos(for priority: TaskPriority) -> DispatchQoS {
        switch priority {
        case .low: return .background
        case .medium: return .utility
        case .high: return .userInitiated
        case .critical: return .userInteractive
        }
    }
}
