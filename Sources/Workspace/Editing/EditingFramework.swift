import Foundation
import Combine

/// Central media processing engine for the Editing module.
/// Coordinates complex rendering tasks, AI operations, and export pipelines.
final class EditingFramework: ObservableObject {
    static let shared = EditingFramework()

    @Published var activeEngines: [UUID: EditingEngine] = [:]

    private init() {}

    /// Registers an active editing engine for a project.
    func registerEngine(_ engine: EditingEngine, for projectID: UUID) {
        activeEngines[projectID] = engine
    }

    /// Unregisters an active editing engine.
    func unregisterEngine(for projectID: UUID) {
        activeEngines.removeValue(forKey: projectID)
    }

    /// Global media processing command execution.
    func executeBatchProcess(projectIDs: [UUID], operation: String) {
        print("Executing batch operation: \(operation) on \(projectIDs.count) projects")
        // Logic for background rendering and AI processing
    }

    /// Exports a project to a file.
    @MainActor
    func exportProject(projectID: UUID) async throws -> URL {
        guard let engine = activeEngines[projectID] else {
            throw NSError(domain: "EditingFramework", code: 404, userInfo: [NSLocalizedDescriptionKey: "No active engine for project"])
        }

        #if os(iOS)
        if let image = engine.renderToImage() {
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(projectID.uuidString).png")
            if let data = image.pngData() {
                try data.write(to: fileURL)
                return fileURL
            } else {
                throw NSError(domain: "EditingFramework", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to generate PNG data"])
            }
        } else {
            throw NSError(domain: "EditingFramework", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to render image"])
        }
        #else
        throw NSError(domain: "EditingFramework", code: 501, userInfo: [NSLocalizedDescriptionKey: "Export not supported on this platform"])
        #endif
    }
}
