import Foundation
import os.log

/// Orchestrates background tasks for AI processing, indexing, and rendering.
final class BackgroundPipeline {
    static let shared = BackgroundPipeline()
    private let queue = DispatchQueue(label: "com.workspace.pipeline", qos: .utility, attributes: .concurrent)
    private let logger = Logger(subsystem: "com.workspace", category: "Pipeline")

    private init() {}

    func enqueue(taskName: String, action: @escaping () async throws -> Void) {
        queue.async {
            Task {
                do {
                    self.logger.info("Starting task: \(taskName)")
                    try await action()
                    self.logger.info("Completed task: \(taskName)")
                } catch {
                    self.logger.error("Task \(taskName) failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

/// Robust workspace-wide logging system.
struct WorkspaceLogger {
    static let general = Logger(subsystem: "com.workspace", category: "General")
    static let db = Logger(subsystem: "com.workspace", category: "Database")
    static let ai = Logger(subsystem: "com.workspace", category: "AI")
    static let render = Logger(subsystem: "com.workspace", category: "Render")
}
