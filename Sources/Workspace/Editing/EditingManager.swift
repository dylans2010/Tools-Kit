import Foundation
import Combine
import SwiftUI

/// Manages media editing projects, imports, and exports.
final class EditingManager: ObservableObject {
    static let shared = EditingManager()

    @Published var projects: [EditingProject] = []
    private var undoStacks: [UUID: [EditingProject]] = [:]
    private var redoStacks: [UUID: [EditingProject]] = [:]

    private let projectsFile = "editing_projects.json"

    private init() {
        loadProjects()
    }

    func createProject(name: String, canvasSize: CGSize) -> EditingProject {
        let project = EditingProject(
            id: UUID(),
            name: name,
            ownerID: UUID(), // Should be real user ID
            layers: [],
            timelineTracks: [],
            canvasSize: canvasSize,
            createdAt: Date(),
            updatedAt: Date(),
            previewImageID: nil,
            metadata: [:]
        )
        projects.append(project)
        saveProjects()

        // Index with Collaboration Framework
        CollaborationFramework.shared.indexObject(id: project.id, type: .mediaProject)

        return project
    }

    func deleteProject(id: UUID) {
        projects.removeAll { $0.id == id }
        saveProjects()
        CollaborationFramework.shared.unindexObject(id: id)
    }

    func saveProject(_ project: EditingProject) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            // Save to undo stack before updating
            var undoStack = undoStacks[project.id] ?? []
            undoStack.append(projects[index])
            undoStacks[project.id] = undoStack
            // Clear redo stack on new change
            redoStacks[project.id] = []

            var updatedProject = project
            updatedProject.updatedAt = Date()
            projects[index] = updatedProject
            saveProjects()
        }
    }

    func undo(projectID: UUID) {
        guard var undoStack = undoStacks[projectID], !undoStack.isEmpty,
              let index = projects.firstIndex(where: { $0.id == projectID }) else { return }

        let previousState = undoStack.removeLast()
        undoStacks[projectID] = undoStack

        var redoStack = redoStacks[projectID] ?? []
        redoStack.append(projects[index])
        redoStacks[projectID] = redoStack

        projects[index] = previousState
        saveProjects()
    }

    func redo(projectID: UUID) {
        guard var redoStack = redoStacks[projectID], !redoStack.isEmpty,
              let index = projects.firstIndex(where: { $0.id == projectID }) else { return }

        let nextState = redoStack.removeLast()
        redoStacks[projectID] = redoStack

        var undoStack = undoStacks[projectID] ?? []
        undoStack.append(projects[index])
        undoStacks[projectID] = undoStack

        projects[index] = nextState
        saveProjects()
    }

    // MARK: - Persistence

    private func saveProjects() {
        do {
            try WorkspacePersistence.shared.save(projects, to: projectsFile)
        } catch {
            print("Error saving projects: \(error)")
        }
    }

    private func loadProjects() {
        do {
            if WorkspacePersistence.shared.exists(filename: projectsFile) {
                projects = try WorkspacePersistence.shared.load([EditingProject].self, from: projectsFile)

                // Re-index all projects
                for project in projects {
                    CollaborationFramework.shared.indexObject(id: project.id, type: .mediaProject)
                }
            }
        } catch {
            print("Error loading projects: \(error)")
        }
    }
}
