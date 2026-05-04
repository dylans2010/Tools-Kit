import Foundation
import Combine

final class TasksManager: ObservableObject {
    static let shared = TasksManager()

    @Published var tasks: [WorkspaceTask] = []
    @Published var categories: [TaskCategory] = []
    private let aiService = AIService.shared
    private let aiDecoder = AIResponseDecoder()

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
        PluginEventBus.shared.emit(type: .taskCreated, payload: ["id": task.id.uuidString, "title": task.title])
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
            if tasks[idx].completed {
                PluginEventBus.shared.emit(type: .taskCompleted, payload: ["id": task.id.uuidString, "title": task.title])
            }
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

    // MARK: - AI Planning

    struct AITaskPlan: Codable {
        let title: String
        let details: String
        let priority: String
        let dueDateISO8601: String?
        let subtasks: [String]
    }

    struct AITasksResponse: Codable {
        let tasks: [AITaskPlan]
        let workloadSummary: String
    }

    private var aiSchemaString: String {
        """
        {
          "type": "object",
          "required": ["tasks", "workloadSummary"],
          "properties": {
            "tasks": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["title", "details", "priority", "subtasks"],
                "properties": {
                  "title": { "type": "string" },
                  "details": { "type": "string" },
                  "priority": { "type": "string" },
                  "dueDateISO8601": { "type": ["string", "null"] },
                  "subtasks": { "type": "array", "items": { "type": "string" } }
                }
              }
            },
            "workloadSummary": { "type": "string" }
          }
        }
        """
    }

    private var aiSchema: AIJSONType {
        .object([
            "tasks": .array(.object([
                "title": .string,
                "details": .string,
                "priority": .string,
                "subtasks": .array(.string)
            ])),
            "workloadSummary": .string
        ])
    }

    @MainActor
    func generateTasksFromPrompt(_ prompt: String) async throws -> AITasksResponse {
        // Force strict JSON output for task generation and workload balancing.
        let enrichedPrompt = """
        Convert this natural language plan into actionable tasks, even if brief or vague. Infer missing scope/time when reasonable, break down larger tasks, rebalance priorities, and suggest due dates:
        \(prompt)
        """
        let json = try await aiService.generateStructuredJSON(
            prompt: enrichedPrompt,
            jsonSchema: aiSchemaString,
            preferredModel: "openrouter/free",
            systemPrompt: "You are a task planning assistant that understands natural language notes and partial requests. Return strict JSON only."
        )
        return try aiDecoder.decode(AITasksResponse.self, from: json, schema: aiSchema)
    }
}
