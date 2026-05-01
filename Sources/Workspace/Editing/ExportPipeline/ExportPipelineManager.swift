import Foundation

/// Represents an item in the render queue.
struct ExportTask: Identifiable, Codable {
    let id: UUID
    let projectID: UUID
    let projectName: String
    var status: ExportStatus
    var progress: Double = 0.0
    let destinationURL: URL?

    enum ExportStatus: String, Codable { case queued, rendering, completed, failed }
}

/// Manages background rendering and export tasks.
final class ExportPipelineManager: ObservableObject {
    static let shared = ExportPipelineManager()

    @Published var activeTasks: [ExportTask] = []

    private init() {}

    func addToQueue(project: EditingProject) {
        let task = ExportTask(id: UUID(), projectID: project.id, projectName: project.name, status: .queued, destinationURL: nil)
        activeTasks.append(task)
        // Implementation for AVAssetExportSession background process
    }

    func cancelTask(id: UUID) {
        activeTasks.removeAll { $0.id == id }
    }
}
