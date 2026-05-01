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
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadProjects() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([EditingProject].self, from: data) {
            projects = decoded

            // Re-index all projects
            for project in projects {
                CollaborationFramework.shared.indexObject(id: project.id, type: .mediaProject)
            }
        }
    }
}
