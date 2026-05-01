import Foundation
import Combine
import SwiftUI

/// Manages media editing projects, imports, and exports.
final class EditingManager: ObservableObject {
    static let shared = EditingManager()

    @Published var projects: [EditingProject] = []

    private let storageKey = "com.tools-kit.editing.projects"

    private init() {
        loadProjects()
    }

    func createProject(name: String, canvasSize: CGSize) -> EditingProject {
        let project = EditingProject(
            id: UUID(),
            name: name,
            layers: [],
            canvasSize: canvasSize,
            createdAt: Date(),
            updatedAt: Date()
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
            var updatedProject = project
            updatedProject.updatedAt = Date()
            projects[index] = updatedProject
            saveProjects()
        }
    }

    // MARK: - Persistence

    private func saveProjects() {
        try? WorkspacePersistence.shared.save(projects, filename: "editing_projects.json")
    }

    private func loadProjects() {
        if let decoded = try? WorkspacePersistence.shared.load(filename: "editing_projects.json", as: [EditingProject].self) {
            projects = decoded

            // Re-index all projects
            for project in projects {
                CollaborationFramework.shared.indexObject(id: project.id, type: .mediaProject)
            }
        }
    }
}
