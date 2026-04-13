import Foundation
import SwiftUI

final class TasksManager: ObservableObject {
    static let shared = TasksManager()

    @Published var tasks: [WorkspaceTask] = []
    @Published var categories: [TaskCategory] = []

    private let tasksURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Workspace/Tasks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("tasks.json")
    }()

    private let categoriesURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Workspace/Tasks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("categories.json")
    }()

    private init() {
        loadCategories()
        loadTasks()
        if categories.isEmpty {
            categories = [
                TaskCategory(name: "Personal", colorHex: "3B82F6"),
                TaskCategory(name: "Work", colorHex: "22C55E"),
                TaskCategory(name: "Health", colorHex: "EF4444")
            ]
            saveCategories()
        }
    }

    // MARK: - Task CRUD

    func addTask(_ task: WorkspaceTask) {
        tasks.append(task)
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
            if tasks[idx].completed { tasks[idx].boardStatus = .done }
            saveTasks()
        }
    }

    func moveTask(_ task: WorkspaceTask, to status: WorkspaceTask.BoardStatus) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].boardStatus = status
            if status == .done { tasks[idx].completed = true }
            saveTasks()
        }
    }

    // MARK: - Category CRUD

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
        tasks = tasks.map { t in
            var task = t
            if task.categoryID == category.id { task.categoryID = nil }
            return task
        }
        saveCategories()
        saveTasks()
    }

    func category(for id: UUID?) -> TaskCategory? {
        guard let id else { return nil }
        return categories.first { $0.id == id }
    }

    // MARK: - Filters

    var todayTasks: [WorkspaceTask] {
        tasks.filter { !$0.completed && ($0.isDueToday || $0.isOverdue) }
            .sorted { $0.priority.rawValue > $1.priority.rawValue }
    }

    var upcomingTasks: [WorkspaceTask] {
        tasks.filter {
            !$0.completed &&
            !$0.isDueToday &&
            !$0.isOverdue &&
            ($0.dueDate != nil)
        }
        .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    var incompleteTasks: [WorkspaceTask] {
        tasks.filter { !$0.completed }
    }

    // MARK: - Persistence

    private func loadTasks() {
        guard let data = try? Data(contentsOf: tasksURL),
              let decoded = try? JSONDecoder().decode([WorkspaceTask].self, from: data) else { return }
        tasks = decoded
    }

    private func saveTasks() {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        try? data.write(to: tasksURL)
    }

    private func loadCategories() {
        guard let data = try? Data(contentsOf: categoriesURL),
              let decoded = try? JSONDecoder().decode([TaskCategory].self, from: data) else { return }
        categories = decoded
    }

    private func saveCategories() {
        guard let data = try? JSONEncoder().encode(categories) else { return }
        try? data.write(to: categoriesURL)
    }
}
