import Foundation
import Combine

class ProjectsManager: ObservableObject {
    static let shared = ProjectsManager()

    @Published var projects: [Project] = []

    private let storageKey = "projects_data"

    init() {
        load()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Project].self, from: data) else { return }
        projects = decoded
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    // MARK: - Project CRUD

    func createProject(_ project: Project) {
        projects.append(project)
        save()
    }

    func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            var updated = project
            updated.updatedAt = Date()
            projects[index] = updated
            save()
        }
    }

    func deleteProject(id: UUID) {
        projects.removeAll { $0.id == id }
        save()
    }

    // MARK: - Task methods

    func addTask(to projectID: UUID, task: ProjectTask) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[index].tasks.append(task)
        projects[index].updatedAt = Date()
        save()
    }

    func updateTask(_ task: ProjectTask, in projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }),
              let tIdx = projects[pIdx].tasks.firstIndex(where: { $0.id == task.id }) else { return }
        projects[pIdx].tasks[tIdx] = task
        projects[pIdx].updatedAt = Date()
        save()
    }

    func deleteTask(id: UUID, from projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[pIdx].tasks.removeAll { $0.id == id }
        projects[pIdx].updatedAt = Date()
        save()
    }

    func toggleTaskStatus(taskID: UUID, in projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }),
              let tIdx = projects[pIdx].tasks.firstIndex(where: { $0.id == taskID }) else { return }
        let current = projects[pIdx].tasks[tIdx].status
        switch current {
        case .todo: projects[pIdx].tasks[tIdx].status = .inProgress
        case .inProgress: projects[pIdx].tasks[tIdx].status = .done
        case .done: projects[pIdx].tasks[tIdx].status = .todo
        }
        projects[pIdx].updatedAt = Date()
        save()
    }

    // MARK: - File methods

    func addFile(to projectID: UUID, file: ProjectFile) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[index].files.append(file)
        projects[index].updatedAt = Date()
        save()
    }

    func deleteFile(id: UUID, from projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[pIdx].files.removeAll { $0.id == id }
        projects[pIdx].updatedAt = Date()
        save()
    }

    // MARK: - Annotation methods

    func addAnnotation(to projectID: UUID, annotation: ProjectAnnotation) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[index].annotations.append(annotation)
        projects[index].updatedAt = Date()
        save()
    }

    func deleteAnnotation(id: UUID, from projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[pIdx].annotations.removeAll { $0.id == id }
        projects[pIdx].updatedAt = Date()
        save()
    }

    // MARK: - Collaborator methods

    func addCollaborator(to projectID: UUID, collaborator: ProjectCollaborator) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[index].collaborators.append(collaborator)
        projects[index].updatedAt = Date()
        save()
    }

    func removeCollaborator(id: UUID, from projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[pIdx].collaborators.removeAll { $0.id == id }
        projects[pIdx].updatedAt = Date()
        save()
    }

    func updateCollaboratorRole(collaboratorID: UUID, role: CollaboratorRole, in projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }),
              let cIdx = projects[pIdx].collaborators.firstIndex(where: { $0.id == collaboratorID }) else { return }
        projects[pIdx].collaborators[cIdx].role = role
        projects[pIdx].updatedAt = Date()
        save()
    }

    // MARK: - Linked Chat

    func addLinkedChat(to projectID: UUID, chat: LinkedChat) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[index].linkedChatIDs.append(chat.id)
        projects[index].updatedAt = Date()
        save()
    }

    // MARK: - Computed

    var activeProjects: [Project] {
        projects.filter { $0.status == .active }
    }

    var completedProjects: [Project] {
        projects.filter { $0.status == .completed }
    }

    func searchProjects(query: String) -> [Project] {
        guard !query.isEmpty else { return projects }
        return projects.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.description.localizedCaseInsensitiveContains(query)
        }
    }
}
