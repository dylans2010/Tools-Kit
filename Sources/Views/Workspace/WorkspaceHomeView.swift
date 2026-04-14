import SwiftUI

struct WorkspaceHomeView: View {
    @State private var selectedTab: WorkspaceTab = .home

    enum WorkspaceTab: String, CaseIterable {
        case home = "Home"
        case notes = "Notes"
        case notebooks = "Notebooks"
        case tasks = "Tasks"
        case more = "More"

        var icon: String {
            switch self {
            case .home: return "square.grid.2x2.fill"
            case .notes: return "note.text"
            case .notebooks: return "book.closed"
            case .tasks: return "checklist"
            case .more: return "ellipsis.circle"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                WorkspaceDashboardView()
            }
            .tabItem {
                Label(WorkspaceTab.home.rawValue, systemImage: WorkspaceTab.home.icon)
            }
            .tag(WorkspaceTab.home)

            NavigationStack {
                NotesView()
            }
            .tabItem {
                Label(WorkspaceTab.notes.rawValue, systemImage: WorkspaceTab.notes.icon)
            }
            .tag(WorkspaceTab.notes)

            NavigationStack {
                NotebooksHomeView()
            }
            .tabItem {
                Label(WorkspaceTab.notebooks.rawValue, systemImage: WorkspaceTab.notebooks.icon)
            }
            .tag(WorkspaceTab.notebooks)

            NavigationStack {
                TasksHomeView()
            }
            .tabItem {
                Label(WorkspaceTab.tasks.rawValue, systemImage: WorkspaceTab.tasks.icon)
            }
            .tag(WorkspaceTab.tasks)

            NavigationStack {
                WorkspaceMoreView()
            }
            .tabItem {
                Label(WorkspaceTab.more.rawValue, systemImage: WorkspaceTab.more.icon)
            }
            .tag(WorkspaceTab.more)
        }
    }
}

// MARK: - Dashboard View

struct WorkspaceDashboardView: View {
    @StateObject private var notebooksManager = NotebooksManager.shared
    @StateObject private var tasksManager = TasksManager.shared
    @StateObject private var habitsManager = HabitsManager.shared

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        else if hour < 17 { return "Good Afternoon" }
        else { return "Good Evening" }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header greeting
                VStack(alignment: .leading, spacing: 6) {
                    Text(greeting)
                        .font(.largeTitle.bold())
                    Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Quick stats
                quickStatsSection

                // Recent Notebooks
                if !notebooksManager.notebooks.isEmpty {
                    sectionHeader("Recent Notebooks", icon: "book.closed.fill", color: .indigo)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(notebooksManager.notebooks.prefix(5)) { notebook in
                                NavigationLink {
                                    NotebookDetailView(notebook: notebook)
                                } label: {
                                    DashboardNotebookCard(notebook: notebook)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Today's Tasks
                if !tasksManager.todayTasks.isEmpty {
                    sectionHeader("Today's Tasks", icon: "checklist", color: .blue)
                    VStack(spacing: 8) {
                        ForEach(tasksManager.todayTasks.prefix(4)) { task in
                            DashboardTaskRow(task: task, manager: tasksManager)
                        }
                    }
                    .padding(.horizontal)
                }

                // Today's Habits
                if !habitsManager.habits.isEmpty {
                    sectionHeader("Habits", icon: "flame.fill", color: .orange)
                    VStack(spacing: 8) {
                        ForEach(habitsManager.habits.prefix(3)) { habit in
                            DashboardHabitRow(habit: habit, manager: habitsManager)
                        }
                    }
                    .padding(.horizontal)
                }

                // Quick access
                quickAccessSection
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Workspace")
        .navigationBarTitleDisplayMode(.large)
    }

    private var quickStatsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                DashboardStatCard(
                    value: "\(notebooksManager.notebooks.count)",
                    label: "Notebooks",
                    icon: "book.closed.fill",
                    gradient: [.indigo, .purple]
                )
                DashboardStatCard(
                    value: "\(tasksManager.todayTasks.count)",
                    label: "Due Today",
                    icon: "calendar.badge.exclamationmark",
                    gradient: [.blue, .cyan]
                )
                DashboardStatCard(
                    value: "\(habitsManager.habits.filter { $0.isCompletedToday() }.count)/\(habitsManager.habits.count)",
                    label: "Habits Done",
                    icon: "flame.fill",
                    gradient: [.orange, .red]
                )
                DashboardStatCard(
                    value: "\(tasksManager.completedTasks.count)",
                    label: "Completed",
                    icon: "checkmark.circle.fill",
                    gradient: [.green, .mint]
                )
            }
            .padding(.horizontal)
        }
    }

    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("All Features", icon: "apps.iphone", color: .secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                NavigationLink { ArticlesHomeView() } label: {
                    QuickAccessButton(label: "Articles", icon: "newspaper", color: .orange)
                }
                .buttonStyle(.plain)
                NavigationLink { SlidesHomeView() } label: {
                    QuickAccessButton(label: "Slides", icon: "rectangle.on.rectangle.angled", color: .blue)
                }
                .buttonStyle(.plain)
                NavigationLink { SpreadsheetsHomeView() } label: {
                    QuickAccessButton(label: "Sheets", icon: "tablecells", color: .green)
                }
                .buttonStyle(.plain)
                NavigationLink { MailHomeView() } label: {
                    QuickAccessButton(label: "Mail", icon: "envelope", color: .red)
                }
                .buttonStyle(.plain)
                NavigationLink { WorkspaceHabitTrackerView() } label: {
                    QuickAccessButton(label: "Habits", icon: "flame.fill", color: .orange)
                }
                .buttonStyle(.plain)
                NavigationLink { CalendarHomeView() } label: {
                    QuickAccessButton(label: "Calendar", icon: "calendar", color: .blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
    }

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.subheadline)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Dashboard Supporting Views

struct DashboardStatCard: View {
    let value: String
    let label: String
    let icon: String
    let gradient: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .cornerRadius(10)

            Text(value)
                .font(.system(.title2, design: .rounded).bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(width: 110)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct DashboardNotebookCard: View {
    let notebook: Notebook

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(width: 140, height: 80)
                    .cornerRadius(10)
                Image(systemName: "book.closed.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
            Text(notebook.name)
                .font(.subheadline.bold())
                .lineLimit(1)
            Text("\(notebook.folders.count) folders")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 140)
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

struct DashboardTaskRow: View {
    let task: WorkspaceTask
    @ObservedObject var manager: TasksManager

    var body: some View {
        HStack(spacing: 12) {
            Button {
                manager.toggleComplete(task)
            } label: {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.completed ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .strikethrough(task.completed)
                    .foregroundColor(task.completed ? .secondary : .primary)
                if let due = task.dueDate {
                    Text(due, style: .date)
                        .font(.caption2)
                        .foregroundColor(task.isOverdue ? .red : .secondary)
                }
            }
            Spacer()

            Image(systemName: task.priority.icon)
                .font(.caption)
                .foregroundColor(Color(hex: task.priority.color) ?? .blue)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct DashboardHabitRow: View {
    let habit: Habit
    @ObservedObject var manager: HabitsManager

    var habitColor: Color { Color(hex: habit.colorHex) ?? .blue }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: habit.icon)
                .font(.body)
                .foregroundColor(habitColor)
                .frame(width: 36, height: 36)
                .background(habitColor.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.subheadline.bold())
                ProgressView(value: Double(min(manager.todayCount(for: habit), habit.targetCount)), total: Double(habit.targetCount))
                    .tint(habitColor)
            }

            Spacer()

            Button {
                manager.increment(habit: habit)
            } label: {
                Image(systemName: habit.isCompletedToday() ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title3)
                    .foregroundColor(habit.isCompletedToday() ? habitColor : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct QuickAccessButton: View {
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.12))
                .cornerRadius(14)
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.primary)
        }
    }
}

// MARK: - More View

struct WorkspaceMoreView: View {
    var body: some View {
        List {
            Section("Create") {
                NavigationLink { ArticlesHomeView() } label: {
                    Label("Articles", systemImage: "newspaper")
                }
                NavigationLink { SlidesHomeView() } label: {
                    Label("Slides", systemImage: "rectangle.on.rectangle.angled")
                }
                NavigationLink { SpreadsheetsHomeView() } label: {
                    Label("Spreadsheets", systemImage: "tablecells")
                }
                NavigationLink { FormsView() } label: {
                    Label("Forms", systemImage: "list.bullet.rectangle.portrait")
                }
            }
            Section("Track") {
                NavigationLink { WorkspaceHabitTrackerView() } label: {
                    Label("Habits", systemImage: "flame.fill")
                }
                NavigationLink { CalendarHomeView() } label: {
                    Label("Calendar", systemImage: "calendar")
                }
            }
            Section("Communicate") {
                NavigationLink { MailHomeView() } label: {
                    Label("Mail", systemImage: "envelope")
                }
            }
        }
        .navigationTitle("More")
        .listStyle(.insetGrouped)
    }
}

