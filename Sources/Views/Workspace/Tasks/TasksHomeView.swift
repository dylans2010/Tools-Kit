import SwiftUI

struct TasksHomeView: View {
    @StateObject private var manager = TasksManager.shared
    @State private var showingCreate = false
    @State private var selectedTask: WorkspaceTask?
    @State private var showingBoard = false
    @State private var showingCategories = false
    @State private var filterCategory: TaskCategory?
    @State private var aiPrompt = ""
    @State private var aiError: String?
    @State private var aiSummary = ""
    @State private var aiLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                stickyHeader
                summaryCards
                aiPlannerCard
                contentSections
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .navigationTitle("Tasks")
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
    }

    private var stickyHeader: some View {
        WorkspaceSurfaceCard {
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Task Command Center")
                            .font(.title3.bold())
                        Text("Plan, prioritize, and execute with AI-guided workflows.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { showingBoard = true } label: {
                        Label("Board", systemImage: "square.grid.2x2")
                    }
                    .buttonStyle(.bordered)
                    Button { showingCreate = true } label: {
                        Label("New", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                HStack(spacing: 8) {
                    aiQuickAction("Sprint Plan", icon: "calendar.badge.plus") {
                        runAIPlanner(with: "Create a 7-day sprint plan with priority, scope, and due dates.")
                    }
                    aiQuickAction("Backlog Triage", icon: "line.3.horizontal.decrease.circle") {
                        runAIPlanner(with: "Triage backlog items and suggest top priority execution order.")
                    }
                    aiQuickAction("Risk Scan", icon: "exclamationmark.triangle") {
                        runAIPlanner(with: "Identify risks, blockers, and mitigation tasks for this plan.")
                    }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: filterCategory == nil) { filterCategory = nil }
                        ForEach(manager.categories) { cat in
                            FilterChip(title: cat.name, color: Color(hex: cat.colorHex) ?? .blue, isSelected: filterCategory?.id == cat.id) {
                                filterCategory = (filterCategory?.id == cat.id) ? nil : cat
                            }
                        }
                        Button {
                            showingCategories = true
                        } label: {
                            Label("Categories", systemImage: "folder")
                                .font(.caption.weight(.medium))
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 8) {
            StatPill(label: "Today", value: "\(manager.todayTasks.count)", color: .blue)
            StatPill(label: "Upcoming", value: "\(manager.upcomingTasks.count)", color: .orange)
            StatPill(label: "Completed", value: "\(manager.completedTasks.count)", color: .green)
        }
    }

    private var aiPlannerCard: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Planning Assistant")
                    .font(.headline)
                TextField("Turn raw notes into structured tasks…", text: $aiPrompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                if aiLoading {
                    WorkspaceSkeletonLine()
                    WorkspaceSkeletonLine(widthRatio: 0.7)
                } else if let aiError {
                    Text(aiError)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if !aiSummary.isEmpty {
                    Text(aiSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Button("Generate Plan", action: runAIPlanner)
                        .buttonStyle(.borderedProminent)
                        .disabled(aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiLoading)
                    Spacer()
                    if !aiSummary.isEmpty {
                        Button("Clear") {
                            aiSummary = ""
                            aiError = nil
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var contentSections: some View {
        if manager.tasks.isEmpty {
            EmptyStateView(
                icon: "checklist",
                title: "No Tasks Yet",
                message: "Create tasks or ask AI to generate a complete task plan.",
                action: { showingCreate = true },
                actionLabel: "Create Task"
            )
        } else {
            if !manager.todayTasks.isEmpty {
                WorkspaceSectionHeader(title: "Today")
                taskList(filterAndSort(manager.todayTasks))
            }
            if !manager.upcomingTasks.isEmpty {
                WorkspaceSectionHeader(title: "Upcoming")
                taskList(filterAndSort(manager.upcomingTasks))
            }
            if !manager.completedTasks.isEmpty {
                WorkspaceSectionHeader(title: "Completed")
                taskList(Array(manager.completedTasks.prefix(8)))
            }
        }
    }

    private func taskList(_ tasks: [WorkspaceTask]) -> some View {
        VStack(spacing: 8) {
            ForEach(tasks) { task in
                TaskRowCard(task: task, manager: manager) { selectedTask = task }
            }
        }
    }

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
                    // Apply decoded AI tasks directly to the task store.
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
                    aiError = "We couldn’t turn that request into tasks. Try adding scope, deadline, and priority hints."
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

    private func aiQuickAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
        }
        .buttonStyle(.bordered)
    }
}

struct TaskRowCard: View {
    let task: WorkspaceTask
    @ObservedObject var manager: TasksManager
    let onTap: () -> Void

    private var priorityColor: Color { Color(hex: task.priority.color) ?? .blue }
    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()

    var body: some View {
        WorkspaceSurfaceCard {
            HStack(spacing: 12) {
                Button { manager.toggleComplete(task) } label: {
                    Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(task.completed ? .green : .secondary)
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.body.weight(.semibold))
                        .strikethrough(task.completed)
                        .onTapGesture(perform: onTap)
                    HStack(spacing: 8) {
                        WorkspaceStatusBadge(title: task.priority.rawValue, color: priorityColor)
                        if let due = task.dueDate {
                            WorkspaceStatusBadge(title: shortDate(due), color: task.isOverdue ? .red : .secondary)
                        }
                    }
                }
                Spacer()
                Button("Open", action: onTap)
                    .buttonStyle(.bordered)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { manager.deleteTask(task) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func shortDate(_ date: Date) -> String {
        Self.shortDateFormatter.string(from: date)
    }
}

struct WorkspaceSurfaceCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
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
