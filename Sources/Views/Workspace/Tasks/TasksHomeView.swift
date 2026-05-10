import SwiftUI

struct TasksHomeView: View {
    @StateObject private var manager = TasksManager.shared
    @State private var showingCreate = false
    @State private var selectedTask: WorkspaceTask?
    @State private var showingBoard = false
    @State private var showingCategories = false
    @State private var showingAISheet = false
    @State private var filterCategory: TaskCategory?
    @State private var aiPrompt = ""
    @State private var aiError: String?
    @State private var aiSummary = ""
    @State private var aiLoading = false

    var body: some View {
        List {
            Section {
                categoryFilterRow
            }

            Section {
                HStack(spacing: 12) {
                    StatLabel(label: "Today", value: "\(manager.todayTasks.count)")
                    StatLabel(label: "Upcoming", value: "\(manager.upcomingTasks.count)")
                    StatLabel(label: "Done", value: "\(manager.completedTasks.count)")
                }
            } header: {
                Text("Summary")
            }

            if manager.tasks.isEmpty {
                ContentUnavailableView {
                    Label("No Tasks Yet", systemImage: "checklist")
                } description: {
                    Text("Create tasks or ask AI to generate a complete task plan.")
                } actions: {
                    Button("Create Task") { showingCreate = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                if !manager.todayTasks.isEmpty {
                    Section {
                        ForEach(filterAndSort(manager.todayTasks)) { task in
                            TaskRow(task: task, manager: manager) { selectedTask = task }
                        }
                    } header: {
                        Text("Today")
                    }
                }
                if !manager.upcomingTasks.isEmpty {
                    Section {
                        ForEach(filterAndSort(manager.upcomingTasks)) { task in
                            TaskRow(task: task, manager: manager) { selectedTask = task }
                        }
                    } header: {
                        Text("Upcoming")
                    }
                }
                if !manager.completedTasks.isEmpty {
                    Section {
                        ForEach(Array(manager.completedTasks.prefix(8))) { task in
                            TaskRow(task: task, manager: manager) { selectedTask = task }
                        }
                    } header: {
                        Text("Completed")
                    }
                }
            }
        }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button { showingBoard = true } label: {
                        Label("Board View", systemImage: "square.grid.2x2")
                    }
                    Button { showingCategories = true } label: {
                        Label("Categories", systemImage: "folder")
                    }
                    Button { showingAISheet = true } label: {
                        Label("AI Assistant", systemImage: "sparkles")
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
            CreateTaskView { manager.addTask($0) }
        }
        .sheet(item: $selectedTask) { task in
            NavigationStack { WorkspaceTaskDetailView(task: task) }
        }
        .sheet(isPresented: $showingBoard) {
            NavigationStack { TaskBoardView() }
        }
        .sheet(isPresented: $showingCategories) {
            NavigationStack { TaskCategoryView() }
        }
        .sheet(isPresented: $showingAISheet) {
            aiToolsSheet
        }
    }

    // MARK: - Subviews

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: filterCategory == nil) { filterCategory = nil }
                ForEach(manager.categories) { cat in
                    FilterChip(title: cat.name, isSelected: filterCategory?.id == cat.id) {
                        filterCategory = (filterCategory?.id == cat.id) ? nil : cat
                    }
                }
            }
        }
    }

    private var aiToolsSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. I need a lightweight product launch plan", text: $aiPrompt, axis: .vertical)
                } header: {
                    Text("Describe your plan")
                } footer: {
                    Text("Type naturally, even rough notes. AI will infer timeline, priority, and subtasks.")
                }

                Section {
                    HStack(spacing: 8) {
                        Button("Sprint") { runAIPlanner(with: "Plan next week from this input with realistic milestones.") }
                            .buttonStyle(.bordered)
                        Button("Triage") { runAIPlanner(with: "Prioritize this backlog and suggest execution order.") }
                            .buttonStyle(.bordered)
                        Button("Risks") { runAIPlanner(with: "Identify blockers and add mitigation tasks.") }
                            .buttonStyle(.bordered)
                    }
                } header: {
                    Text("Quick Actions")
                }

                Section {
                    if aiLoading {
                        ProgressView("Generating plan…")
                    } else if let aiError {
                        Label(aiError, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    } else if !aiSummary.isEmpty {
                        Text(aiSummary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Button("Generate Plan", action: runAIPlanner)
                        .buttonStyle(.borderedProminent)
                        .disabled(aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiLoading)

                    if !aiSummary.isEmpty {
                        Button("Clear") {
                            aiSummary = ""
                            aiError = nil
                        }
                    }
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingAISheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Logic

    private func runAIPlanner() {
        runAIPlanner(with: aiPrompt)
    }

    private func runAIPlanner(with promptInput: String) {
        let prompt = promptInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        aiLoading = true
        aiError = nil
        let formatter = ISO8601DateFormatter()
        Task {
            do {
                let response = try await manager.generateTasksFromPrompt(prompt)
                await MainActor.run {
                    for planned in response.tasks {
                        let priority = priorityFromAI(planned.priority)
                        let due = planned.dueDateISO8601.flatMap(formatter.date(from:))
                        manager.addTask(
                            WorkspaceTask(
                                title: planned.title,
                                description: formattedTaskDescription(details: planned.details, subtasks: planned.subtasks),
                                dueDate: due,
                                priority: priority
                            )
                        )
                    }
                    aiSummary = response.workloadSummary
                    aiPrompt = ""
                    aiLoading = false
                }
            } catch {
                await MainActor.run {
                    aiError = "Couldn't convert this yet. Natural language is supported, so short plain requests are fine."
                    aiLoading = false
                }
            }
        }
    }

    private func priorityFromAI(_ value: String) -> WorkspaceTask.TaskPriority {
        switch value.lowercased() {
        case "critical": return .critical
        case "high": return .high
        case "low": return .low
        default: return .medium
        }
    }

    private func filterAndSort(_ tasks: [WorkspaceTask]) -> [WorkspaceTask] {
        var result = tasks
        if let cat = filterCategory {
            result = result.filter { $0.categoryID == cat.id }
        }
        result.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        return result
    }

    private func formattedTaskDescription(details: String, subtasks: [String]) -> String {
        guard !subtasks.isEmpty else { return details }
        return details + "\n" + subtasks.map { "• \($0)" }.joined(separator: "\n")
    }
}

// MARK: - Supporting Views

private struct TaskRow: View {
    let task: WorkspaceTask
    @ObservedObject var manager: TasksManager
    let onTap: () -> Void

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Button { manager.toggleComplete(task) } label: {
                    Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.body.weight(.semibold))
                        .strikethrough(task.completed)
                    HStack(spacing: 6) {
                        Label(task.priority.rawValue, systemImage: task.priority.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let due = task.dueDate {
                            Label(Self.shortDateFormatter.string(from: due), systemImage: "calendar")
                                .font(.caption)
                                .foregroundStyle(task.isOverdue ? .red : .secondary)
                        }
                    }
                }
                Spacer()
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { manager.deleteTask(task) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

private struct StatLabel: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WorkspaceSectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
        }
    }
}

struct WorkspaceStatusBadge: View {
    let title: String
    let color: Color
    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct WorkspaceSkeletonLine: View {
    var widthRatio: CGFloat = 1
    var body: some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.2))
                .frame(width: max(40, proxy.size.width * widthRatio), height: 12, alignment: .leading)
                .redacted(reason: .placeholder)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 12)
    }
}
