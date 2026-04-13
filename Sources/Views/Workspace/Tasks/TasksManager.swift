import Foundation
import Combine

final class TasksManager: ObservableObject {
    static let shared = TasksManager()

    @Published var tasks: [WorkspaceTask] = []
    @Published var categories: [TaskCategory] = []

    private var saveDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Workspace/Tasks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var tasksURL: URL { saveDir.appendingPathComponent("tasks.json") }
    private var categoriesURL: URL { saveDir.appendingPathComponent("categories.json") }

    private init() {
        loadCategories()
        loadTasks()
        if categories.isEmpty {
            categories = [
                TaskCategory(name: "Personal", colorHex: "#007AFF"),
                TaskCategory(name: "Work", colorHex: "#FF9500"),
                TaskCategory(name: "Health", colorHex: "#34C759")
            ]
            saveCategories()
        }
    }

    // MARK: - Tasks CRUD

    func addTask(_ task: WorkspaceTask) {
        tasks.insert(task, at: 0)
        saveTasks()
    }

    func updateTask(_ task: WorkspaceTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
            saveTasks()
        }
    }

    func deleteTask(_ task: WorkspaceTask) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    func toggleComplete(_ task: WorkspaceTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].completed.toggle()
            saveTasks()
        }
    }

    // MARK: - Categories CRUD

    func addCategory(_ category: TaskCategory) {
        categories.append(category)
        saveCategories()
    }

    func updateCategory(_ category: TaskCategory) {
        if let idx = categories.firstIndex(where: { $0.id == category.id }) {
            categories[idx] = category
            saveCategories()
        }
    }

    func deleteCategory(_ category: TaskCategory) {
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }

    func category(for task: WorkspaceTask) -> TaskCategory? {
        guard let id = task.categoryID else { return nil }
        return categories.first { $0.id == id }
    }

    // MARK: - Queries

    var todayTasks: [WorkspaceTask] {
        tasks.filter { !$0.completed && ($0.isDueToday || $0.isOverdue) }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    var upcomingTasks: [WorkspaceTask] {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return tasks.filter { !$0.completed && ($0.dueDate == nil || ($0.dueDate ?? Date()) >= tomorrow) }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    var completedTasks: [WorkspaceTask] {
        tasks.filter { $0.completed }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Persistence

    private func loadTasks() {
        guard let data = try? Data(contentsOf: tasksURL),
              let decoded = try? JSONDecoder().decode([WorkspaceTask].self, from: data) else { return }
        tasks = decoded
    }

    private func saveTasks() {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        try? data.write(to: tasksURL, options: .atomic)
    }

    private func loadCategories() {
        guard let data = try? Data(contentsOf: categoriesURL),
              let decoded = try? JSONDecoder().decode([TaskCategory].self, from: data) else { return }
        categories = decoded
    }

    private func saveCategories() {
        guard let data = try? JSONEncoder().encode(categories) else { return }
        try? data.write(to: categoriesURL, options: .atomic)
    }
}
