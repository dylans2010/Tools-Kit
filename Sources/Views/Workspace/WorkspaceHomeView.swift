import SwiftUI

struct WorkspaceHomeView: View {
    @State private var selectedTab: WorkspaceTab = .overview

    enum WorkspaceTab: String, CaseIterable {
        case overview = "Overview"
        case notes = "Notes"
        case mail = "Mail"
        case notebooks = "Notebooks"
        case tasks = "Tasks"
        case articles = "Articles"
        case files = "Files"

        var icon: String {
            switch self {
            case .overview: return "house.fill"
            case .notes: return "note.text"
            case .mail: return "envelope.fill"
            case .notebooks: return "book.closed.fill"
            case .tasks: return "checklist"
            case .articles: return "newspaper.fill"
            case .files: return "folder.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            overviewTab
            notesTab
            mailTab
            notebooksTab
            tasksTab
            articlesTab
            filesTab
        }
    }

    private var overviewTab: some View {
        NavigationStack {
            WorkspaceDashboardView()
        }
        .tabItem {
            Label(WorkspaceTab.overview.rawValue, systemImage: WorkspaceTab.overview.icon)
        }
        .tag(WorkspaceTab.overview)
    }

    private var notesTab: some View {
        NavigationStack {
            NotesView()
        }
        .tabItem {
            Label(WorkspaceTab.notes.rawValue, systemImage: WorkspaceTab.notes.icon)
        }
        .tag(WorkspaceTab.notes)
    }

    private var mailTab: some View {
        NavigationStack {
            WorkspaceMailRouterView()
        }
        .tabItem {
            Label(WorkspaceTab.mail.rawValue, systemImage: WorkspaceTab.mail.icon)
        }
        .tag(WorkspaceTab.mail)
    }

    private var notebooksTab: some View {
        NavigationStack {
            NotebooksHomeView()
        }
        .tabItem {
            Label(WorkspaceTab.notebooks.rawValue, systemImage: WorkspaceTab.notebooks.icon)
        }
        .tag(WorkspaceTab.notebooks)
    }

    private var tasksTab: some View {
        NavigationStack {
            TasksHomeView()
        }
        .tabItem {
            Label(WorkspaceTab.tasks.rawValue, systemImage: WorkspaceTab.tasks.icon)
        }
        .tag(WorkspaceTab.tasks)
    }

    private var articlesTab: some View {
        NavigationStack {
            ArticlesHomeView()
        }
        .tabItem {
            Label(WorkspaceTab.articles.rawValue, systemImage: WorkspaceTab.articles.icon)
        }
        .tag(WorkspaceTab.articles)
    }

    private var filesTab: some View {
        NavigationStack {
            FileManagementView()
        }
        .tabItem {
            Label(WorkspaceTab.files.rawValue, systemImage: WorkspaceTab.files.icon)
        }
        .tag(WorkspaceTab.files)
    }
}

// MARK: - Dashboard View

struct WorkspaceDashboardView: View {
    @StateObject private var notebooksManager = NotebooksManager.shared
    @StateObject private var tasksManager = TasksManager.shared
    @StateObject private var articlesManager = ArticlesManager.shared
    @StateObject private var calendarManager = CalendarManager.shared
    @StateObject private var habitsManager = HabitsManager.shared

    @StateObject private var settingsManager = AIChatSettingsManager.shared

    @State private var showingCreateTask = false
    @State private var showingCreateNotebook = false
    @State private var showingSettings = false

    private let moreTools: [(title: String, icon: String, color: Color, destination: AnyView)] = [
        ("Calendar", "calendar", .green, AnyView(CalendarHomeView())),
        ("Habits", "flame.fill", .red, AnyView(WorkspaceHabitTrackerView())),
        ("Files", "folder.fill", .yellow, AnyView(FileManagementView())),
        ("Feedback", "bubble.left.and.bubble.right.fill", .orange, AnyView(FeedbackView())),
        ("Forms", "list.bullet.rectangle.portrait", .teal, AnyView(FormsView())),
        ("Slides", "rectangle.on.rectangle.angled", .purple, AnyView(SlidesHomeView())),
        ("Sheets", "tablecells", .blue, AnyView(SpreadsheetsHomeView())),
        ("Workouts", "figure.strengthtraining.traditional", .mint, AnyView(WorkoutsHomeView())),
        ("AI Mentor", "sparkles", .pink, AnyView(AIMentorView())),
        ("Meet", "video.fill", .cyan, AnyView(JoinMeetingView()))
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                welcomeHeader
                quickActionsSection
                quickStatsSection
                moreToolsSection
                todaysEventsSection
                habitsSection
                recentNotebooksSection
                todaysTasksSection
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Workspace")
        .navigationBarItems(
            trailing: Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
            }
        )
        .sheet(isPresented: $showingSettings) {
            AIChatSettingsView(settings: $settingsManager.settings)
        }
        .sheet(isPresented: $showingCreateTask) {
            CreateTaskView { task in tasksManager.addTask(task) }
        }
        .sheet(isPresented: $showingCreateNotebook) {
            CreateNotebookView()
        }
    }

    private var quickActionsSection: some View {
        dashboardSection(title: "Quick Actions", icon: "bolt.fill", color: .yellow) {
            HStack(spacing: 12) {
                quickActionButton("New Task", icon: "plus.circle.fill", color: .blue) {
                    showingCreateTask = true
                }
                quickActionButton("New Notebook", icon: "book.closed.fill", color: .indigo) {
                    showingCreateNotebook = true
                }
                NavigationLink(destination: ArticleSearchView()) {
                    VStack(spacing: 8) {
                        Image(systemName: "newspaper.fill")
                            .font(.title3)
                            .foregroundColor(.orange)
                            .padding(12)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Circle())
                        Text("Find Article")
                            .font(.caption.bold())
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
    }

    private var quickStatsSection: some View {
        dashboardSection(title: "Quick Stats", icon: "chart.bar.fill", color: .teal) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                WorkspaceStatCard(value: "\(notebooksManager.notebooks.count)", label: "Notebooks", icon: "book.closed.fill", color: .indigo)
                WorkspaceStatCard(value: "\(tasksManager.todayTasks.count)", label: "Tasks Today", icon: "checklist", color: .blue)
                WorkspaceStatCard(value: "\(articlesManager.recentArticles.count)", label: "Articles Saved", icon: "newspaper.fill", color: .orange)
                WorkspaceStatCard(value: "\(habitsManager.habits.filter { $0.isCompletedToday() }.count)/\(habitsManager.habits.count)", label: "Habits Done", icon: "flame.fill", color: .red)
            }
            .padding(.horizontal)
        }
    }

    private var moreToolsSection: some View {
        dashboardSection(title: "More Tools", icon: "square.grid.2x2.fill", color: .purple) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(moreTools, id: \.title) { tool in
                    NavigationLink(destination: tool.destination) {
                        VStack(spacing: 12) {
                            Image(systemName: tool.icon)
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(tool.color))

                            Text(tool.title)
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private var todaysEventsSection: some View {
        let todayEvents = calendarManager.events(on: Date())
        return dashboardSection(title: "Today's Events", icon: "calendar", color: .green) {
            VStack(spacing: 10) {
                if todayEvents.isEmpty {
                    Text("No Events Today")
                        .foregroundColor(.secondary)
                        .font(.callout)
                        .padding(.horizontal)
                } else {
                    ForEach(todayEvents.prefix(3)) { event in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: event.priority.color) ?? .green)
                                .frame(width: 4, height: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.subheadline.bold())
                                    .lineLimit(1)
                                Text(event.formattedTimeRange)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                }
                NavigationLink("View Calendar") {
                    CalendarHomeView()
                }
                .font(.caption.bold())
                .padding(.horizontal)
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var habitsSection: some View {
        if !habitsManager.habits.isEmpty {
            dashboardSection(title: "Today's Habits", icon: "flame.fill", color: .red) {
                habitsProgress
            }
        }
    }

    private var habitsProgress: some View {
        let completedCount = habitsManager.habits.filter { $0.isCompletedToday() }.count
        let total = habitsManager.habits.count
        let progress = total > 0 ? Double(completedCount) / Double(total) : 0.0
        return VStack(spacing: 10) {
            HStack {
                Text("\(Int(progress * 100))% Complete")
                    .font(.subheadline.bold())
                    .foregroundColor(.red)
                Spacer()
                Text("\(completedCount)/\(total) Habits")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            ProgressView(value: progress)
                .tint(.red)
                .padding(.horizontal)

            ForEach(habitsManager.habits.prefix(4)) { habit in
                HStack {
                    Image(systemName: habit.icon)
                        .foregroundColor(Color(hex: habit.colorHex) ?? .blue)
                        .frame(width: 24)
                    Text(habit.name)
                        .font(.subheadline)
                        .lineLimit(1)
                    Spacer()
                    if habit.isCompletedToday() {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Text("\(habit.todayCount())/\(habit.targetCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }

    private var recentNotebooksSection: some View {
        dashboardSection(title: "Recent Notebooks", icon: "book.closed.fill", color: .indigo) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if notebooksManager.notebooks.isEmpty {
                        Text("No Notebooks Yet").foregroundColor(.secondary).font(.callout)
                    }
                    ForEach(notebooksManager.notebooks.prefix(5)) { notebook in
                        NavigationLink(destination: NotebookDetailView(notebook: notebook)) {
                            DashboardCard(title: notebook.name, subtitle: "\(notebook.folders.count) Folders", icon: "book.closed.fill", color: .indigo)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var todaysTasksSection: some View {
        dashboardSection(title: "Today's Tasks", icon: "checklist", color: .blue) {
            VStack(spacing: 12) {
                if tasksManager.todayTasks.isEmpty {
                    Text("All Caught Up!").foregroundColor(.secondary).font(.callout).padding(.vertical, 8)
                }
                ForEach(tasksManager.todayTasks.prefix(3)) { task in
                    HStack {
                        Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.completed ? .green : .secondary)
                        Text(task.title)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        if let due = task.dueDate {
                            Text(due, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
    }

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back!")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Summary")
                .font(.title2.bold())
        }
        .padding(.horizontal)
    }

    private func quickActionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .padding(12)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func dashboardSection<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundColor(color)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            content()
        }
    }
}

struct WorkspaceStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .padding(10)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

struct DashboardCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .padding(10)
                .background(color.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .frame(width: 160, height: 140, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct WorkspaceMailRouterView: View {
    @StateObject private var mailStore = MailStore.shared
    @State private var showingManageAccounts = false

    var body: some View {
        Group {
            if let active = mailStore.activeAccount {
                InboxView(account: active, folder: .inbox)
            } else {
                ContentUnavailableView(
                    "No Mail Account Connected",
                    systemImage: "envelope.badge",
                    description: Text("Add an account to open Inbox as your default mail workspace.")
                )
                .navigationTitle("Mail")
                .navigationBarItems(
                    trailing: HStack(spacing: 16) {
                        Button {
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                        .disabled(true)
                        .accessibilityLabel("Compose unavailable without mail account")

                        Button {
                            showingManageAccounts = true
                        } label: {
                            Image(systemName: "person.crop.circle.badge.gearshape")
                        }
                    }
                )
                .sheet(isPresented: $showingManageAccounts) {
                    ManageAccountsView { selectedAccount in
                        mailStore.setActiveAccount(selectedAccount.id)
                        mailStore.reloadAccounts()
                    }
                }
            }
        }
        .onAppear {
            mailStore.reloadAccounts()
        }
    }
}
