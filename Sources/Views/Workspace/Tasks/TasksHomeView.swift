import SwiftUI

struct TasksHomeView: View {
    @StateObject private var manager = TasksManager.shared
    @State private var showingCreate = false
    @State private var selectedTask: WorkspaceTask? = nil
    @State private var showingBoard = false
    @State private var showingCategories = false
    @State private var filterCategory: TaskCategory? = nil
    @State private var sortBy: SortOption = .dueDate

    enum SortOption: String, CaseIterable {
        case dueDate = "Due Date"
        case priority = "Priority"
        case created = "Created"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                summaryCards

                filterBar

                if !manager.todayTasks.isEmpty {
                    taskSection(title: "Today & Overdue", tasks: filterAndSort(manager.todayTasks), isOverdueSection: true)
                }

                if !manager.upcomingTasks.isEmpty {
                    taskSection(title: "Upcoming", tasks: filterAndSort(manager.upcomingTasks), isOverdueSection: false)
                }

                if !manager.completedTasks.isEmpty {
                    completedSection
                }

                if manager.tasks.isEmpty {
                    EmptyStateView(
                        icon: "checklist",
                        title: "No Tasks",
                        message: "Stay productive by adding tasks and tracking your progress.",
                        action: { showingCreate = true },
                        actionLabel: "Add Task"
                    )
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button { showingBoard = true } label: {
                        Label("Board View", systemImage: "square.grid.3x1.fill.below.line.grid.1x2")
                    }
                    Button { showingCategories = true } label: {
                        Label("Manage Categories", systemImage: "folder")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                Button { showingCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            CreateTaskView { task in
                manager.addTask(task)
            }
        }
        .sheet(item: $selectedTask) { task in
            NavigationStack {
                WorkspaceTaskDetailView(task: task)
            }
        }
        .sheet(isPresented: $showingBoard) {
            NavigationStack { TaskBoardView() }
        }
        .sheet(isPresented: $showingCategories) {
            NavigationStack { TaskCategoryView() }
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            StatPill(label: "Today", value: "\(manager.todayTasks.count)", color: .blue)
            StatPill(label: "Upcoming", value: "\(manager.upcomingTasks.count)", color: .orange)
            StatPill(label: "Done", value: "\(manager.completedTasks.count)", color: .green)
        }
        .padding(.horizontal)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: filterCategory == nil) {
                    filterCategory = nil
                }
                ForEach(manager.categories) { cat in
                    FilterChip(title: cat.name, color: Color(hex: cat.colorHex), isSelected: filterCategory?.id == cat.id) {
                        filterCategory = (filterCategory?.id == cat.id) ? nil : cat
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func taskSection(title: String, tasks: [WorkspaceTask], isOverdueSection: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            ForEach(tasks) { task in
                TaskRowCard(task: task, manager: manager) {
                    selectedTask = task
                }
            }
        }
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Completed")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ForEach(manager.completedTasks.prefix(5)) { task in
                TaskRowCard(task: task, manager: manager) {
                    selectedTask = task
                }
            }
        }
    }

    private func filterAndSort(_ tasks: [WorkspaceTask]) -> [WorkspaceTask] {
        var result = tasks
        if let cat = filterCategory {
            result = result.filter { $0.categoryID == cat.id }
        }
        switch sortBy {
        case .dueDate:
            result.sort { (t1: WorkspaceTask, t2: WorkspaceTask) in
                (t1.dueDate ?? .distantFuture) < (t2.dueDate ?? .distantFuture)
            }
        case .priority:
            result.sort { (t1: WorkspaceTask, t2: WorkspaceTask) in
                priorityOrder(t1.priority) > priorityOrder(t2.priority)
            }
        case .created:
            result.sort { (t1: WorkspaceTask, t2: WorkspaceTask) in
                t1.createdAt > t2.createdAt
            }
        }
        return result
    }

    private func priorityOrder(_ p: WorkspaceTask.TaskPriority) -> Int {
        switch p {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

struct TaskRowCard: View {
    let task: WorkspaceTask
    @ObservedObject var manager: TasksManager
    let onTap: () -> Void

    private var priorityColor: Color {
        Color(hex: task.priority.color) ?? .blue
    }

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Button {
                    manager.toggleComplete(task)
                } label: {
                    Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(task.completed ? .green : .secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline.bold())
                        .strikethrough(task.completed)
                        .foregroundColor(task.completed ? .secondary : .primary)

                    HStack(spacing: 8) {
                        if let due = task.dueDate {
                            Label(shortDate(due), systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(task.isOverdue ? .red : .secondary)
                        }
                        if let cat = manager.category(for: task) {
                            Text(cat.name)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: cat.colorHex)?.opacity(0.2) ?? Color.blue.opacity(0.2))
                                .foregroundColor(Color(hex: cat.colorHex) ?? .blue)
                                .clipShape(Capsule())
                        }
                    }
                }
                .onTapGesture { onTap() }

                Spacer()

                Image(systemName: task.priority.icon)
                    .foregroundColor(priorityColor)
                    .font(.caption)
            }
            .padding()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                manager.deleteTask(task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                manager.toggleComplete(task)
            } label: {
                Label(task.completed ? "Undo" : "Done", systemImage: task.completed ? "arrow.uturn.backward" : "checkmark")
            }
            .tint(.green)
        }
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f.string(from: date)
    }
}
