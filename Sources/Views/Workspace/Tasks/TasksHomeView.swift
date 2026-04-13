import SwiftUI

struct TasksHomeView: View {
    @StateObject private var manager = TasksManager.shared
    @State private var showingCreate = false
    @State private var showingCategories = false
    @State private var showingBoard = false
    @State private var showingAI = false
    @State private var selectedTask: WorkspaceTask?
    @State private var showingTaskDetail = false
    @State private var aiOutput = ""
    @State private var isLoadingAI = false
    @State private var filter: TaskFilter = .all

    enum TaskFilter: String, CaseIterable {
        case all = "All", today = "Today", upcoming = "Upcoming", completed = "Done"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                summaryCards
                filterPicker
                taskList
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Button { showingCategories = true } label: { Label("Categories", systemImage: "tag") }
                    Button { showingBoard = true } label: { Label("Board View", systemImage: "square.grid.3x1.folder.fill.badge.plus") }
                    Button { showingAI = true } label: { Label("AI Assistant", systemImage: "sparkles") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingCreate = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingCreate) { CreateTaskView(manager: manager) }
        .sheet(isPresented: $showingCategories) { TaskCategoryView(manager: manager) }
        .sheet(isPresented: $showingBoard) { NavigationStack { TaskBoardView(manager: manager) } }
        .sheet(isPresented: $showingAI) { aiSheet }
        .navigationDestination(isPresented: $showingTaskDetail) {
            if let task = selectedTask {
                TaskDetailView(task: task, manager: manager)
            }
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                summaryCard("Today", value: "\(manager.todayTasks.count)", icon: "calendar", color: .blue)
                summaryCard("Upcoming", value: "\(manager.upcomingTasks.count)", icon: "clock", color: .orange)
                summaryCard("Total", value: "\(manager.tasks.count)", icon: "list.bullet", color: .purple)
                summaryCard("Done", value: "\(manager.tasks.filter(\.completed).count)", icon: "checkmark.circle.fill", color: .green)
            }
            .padding(.horizontal)
        }
    }

    private func summaryCard(_ title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Image(systemName: icon).foregroundColor(color); Spacer() }
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(width: 100)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    // MARK: - Filter

    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TaskFilter.allCases, id: \.self) { f in
                    Button {
                        filter = f
                    } label: {
                        Text(f.rawValue)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(filter == f ? Color.accentColor : Color(.systemGray5))
                            .foregroundColor(filter == f ? .white : .primary)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Task List

    private var filteredTasks: [WorkspaceTask] {
        switch filter {
        case .all: return manager.tasks.filter { !$0.completed }.sorted { $0.createdAt > $1.createdAt }
        case .today: return manager.todayTasks
        case .upcoming: return manager.upcomingTasks
        case .completed: return manager.tasks.filter { $0.completed }.sorted { $0.createdAt > $1.createdAt }
        }
    }

    private var taskList: some View {
        VStack(alignment: .leading, spacing: 8) {
            if filteredTasks.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "No Tasks",
                    message: "Add a task to get started.",
                    action: { showingCreate = true },
                    actionLabel: "Add Task"
                )
            } else {
                ForEach(filteredTasks) { task in
                    TaskRowView(task: task, manager: manager) {
                        selectedTask = task
                        showingTaskDetail = true
                    }
                }
            }
        }
    }

    // MARK: - AI Sheet

    private var aiSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isLoadingAI {
                    ProgressView("Analyzing your tasks…").padding()
                } else if !aiOutput.isEmpty {
                    ScrollView { Text(aiOutput).padding().font(.body) }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles").font(.system(size: 40)).foregroundColor(.purple)
                        Text("AI Task Assistant").font(.title2.bold())
                        Text("Get smart suggestions to prioritize and organize your workload.").multilineTextAlignment(.center).foregroundColor(.secondary)
                    }
                    .padding()
                }
                Spacer()
                VStack(spacing: 10) {
                    aiActionButton("Summarize Workload", icon: "text.alignleft") { summarizeWorkload() }
                    aiActionButton("Suggest Priorities", icon: "arrow.up.circle") { suggestPriorities() }
                    aiActionButton("Generate Schedule", icon: "calendar.badge.clock") { generateSchedule() }
                }
                .padding()
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Done") { showingAI = false } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !aiOutput.isEmpty { Button("Clear") { aiOutput = "" } }
                }
            }
        }
    }

    private func aiActionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(isLoadingAI)
    }

    private func summarizeWorkload() {
        let taskList = manager.incompleteTasks.map { "- \($0.title) [\($0.priority.rawValue)]" }.joined(separator: "\n")
        let prompt = "Summarize this task list and give me key insights:\n\(taskList.isEmpty ? "No tasks yet." : taskList)"
        runAI(prompt: prompt)
    }

    private func suggestPriorities() {
        let taskList = manager.incompleteTasks.map { "- \($0.title) (due: \($0.dueDate.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .none) } ?? "no date"))" }.joined(separator: "\n")
        let prompt = "Given these tasks, suggest the best priority order and explain why:\n\(taskList.isEmpty ? "No tasks." : taskList)"
        runAI(prompt: prompt)
    }

    private func generateSchedule() {
        let taskList = manager.incompleteTasks.prefix(10).map { "- \($0.title)" }.joined(separator: "\n")
        let prompt = "Create an optimized daily schedule for these tasks:\n\(taskList.isEmpty ? "No tasks." : taskList)"
        runAI(prompt: prompt)
    }

    private func runAI(prompt: String) {
        isLoadingAI = true
        aiOutput = ""
        Task {
            do {
                let result = try await AIService.shared.processText(
                    prompt: prompt,
                    systemPrompt: "You are a productivity expert and task management coach. Be concise and actionable."
                )
                await MainActor.run { aiOutput = result; isLoadingAI = false }
            } catch {
                await MainActor.run { aiOutput = "Could not load suggestions. Check your AI settings."; isLoadingAI = false }
            }
        }
    }
}

// MARK: - Task Row

struct TaskRowView: View {
    let task: WorkspaceTask
    @ObservedObject var manager: TasksManager
    let onTap: () -> Void

    private var priorityColor: Color { Color(hex: task.priority.color) ?? .blue }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Button {
                    manager.toggleComplete(task)
                } label: {
                    Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(task.completed ? .green : .secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline.bold())
                        .strikethrough(task.completed)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Label(task.priority.rawValue, systemImage: task.priority.icon)
                            .font(.caption)
                            .foregroundColor(priorityColor)

                        if let due = task.dueDate {
                            Label(due, style: .date)
                                .font(.caption)
                                .foregroundColor(task.isOverdue ? .red : .secondary)
                        }
                    }
                }

                Spacer()

                if let cat = manager.category(for: task.categoryID) {
                    Text(cat.name)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((Color(hex: cat.colorHex) ?? .blue).opacity(0.15))
                        .foregroundColor(Color(hex: cat.colorHex) ?? .blue)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(14)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) { manager.deleteTask(task) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
