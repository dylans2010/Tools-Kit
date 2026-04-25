import Foundation
import Combine

/// Aggregates agent activities into a coherent session state for UI views.
final class AgentSessionState: ObservableObject, Identifiable {
    let id: String
    let workspaceId: String

    @Published var selectedTab: Int = 0
    @Published var toolExecutions: [AgentToolExecution] = []
    @Published var memory: [String: AgentMemoryEntry] = [:]
    @Published var checkpoints: [AgentCheckpoint] = []
    @Published var diffs: [String: AgentDiff] = [:]
    @Published var timeline: [AgentTimelineStep] = []
    @Published var timelineTools: [String: [AgentToolExecution]] = [:] // Map step ID to tool executions
    @Published var workspaceFiles: [String] = [] // Simplified file list for the file tree
    @Published var lastError: String?
    @Published var isCompleted = false

    init(sessionId: String, workspaceId: String) {
        self.id = sessionId
        self.workspaceId = workspaceId
    }

    private var processedActivityIds: Set<String> = []

    /// Updates the state based on a list of activities.
    func update(with activities: [AgentActivity]) {
        // Filter out already processed activities and sort by createTime
        let newActivities = activities
            .filter { !processedActivityIds.contains($0.id) }
            .sorted { $0.createTime < $1.createTime }

        for activity in newActivities {
            processedActivityIds.insert(activity.id)
            if let tool = activity.toolExecuted {
                if !toolExecutions.contains(where: { $0.requestId == tool.requestId }) {
                    toolExecutions.append(tool)

                    // Associate tool with active timeline step
                    if let activeStep = timeline.last(where: { $0.status == "in_progress" }) {
                        var tools = timelineTools[activeStep.id] ?? []
                        tools.append(tool)
                        timelineTools[activeStep.id] = tools
                    }

                    // Update workspace files if it was a file-modifying tool
                    if ["write_file", "delete_file", "move_file", "list_files"].contains(tool.tool) {
                        updateWorkspace(from: tool)
                    }
                }
            }

            if let memoryEntry = activity.memoryUpdated {
                memory[memoryEntry.key] = memoryEntry
            }

            if let checkpoint = activity.checkpointCreated {
                if !checkpoints.contains(where: { $0.id == checkpoint.id }) {
                    checkpoints.append(checkpoint)
                }
            }

            if let diff = activity.diffGenerated {
                diffs[diff.filePath] = diff
            }

            if let timelineStep = activity.timelineUpdated {
                if let index = timeline.firstIndex(where: { $0.id == timelineStep.id }) {
                    timeline[index] = timelineStep
                } else {
                    timeline.append(timelineStep)
                }
            }

            if activity.sessionCompleted != nil {
                isCompleted = true
            }
        }
    }

    private func updateWorkspace(from tool: AgentToolExecution) {
        // In a real scenario, we'd parse tool output to update workspaceFiles
        // For now, we'll just track that it might have changed
        if tool.tool == "list_files", let files = tool.output["files"]?.value as? [String] {
            self.workspaceFiles = files
        }
    }
}
