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
        case more = "More"

        var icon: String {
            switch self {
            case .overview: return "house.fill"
            case .notes: return "note.text"
            case .mail: return "envelope.fill"
            case .notebooks: return "book.closed.fill"
            case .tasks: return "checklist"
            case .articles: return "newspaper.fill"
            case .more: return "ellipsis.circle.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                WorkspaceDashboardView()
            }
            .tabItem {
                Label(WorkspaceTab.overview.rawValue, systemImage: WorkspaceTab.overview.icon)
            }
            .tag(WorkspaceTab.overview)

            NavigationStack {
                NotesView()
            }
            .tabItem {
                Label(WorkspaceTab.notes.rawValue, systemImage: WorkspaceTab.notes.icon)
            }
            .tag(WorkspaceTab.notes)

            NavigationStack {
                MailHomeView()
            }
            .tabItem {
                Label(WorkspaceTab.mail.rawValue, systemImage: WorkspaceTab.mail.icon)
            }
            .tag(WorkspaceTab.mail)

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
                ArticlesHomeView()
            }
            .tabItem {
                Label(WorkspaceTab.articles.rawValue, systemImage: WorkspaceTab.articles.icon)
            }
            .tag(WorkspaceTab.articles)

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
    @StateObject private var articlesManager = ArticlesManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                welcomeHeader

                dashboardSection(title: "Recent Notebooks", icon: "book.closed.fill", color: .indigo) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            if notebooksManager.notebooks.isEmpty {
                                Text("No notebooks yet").foregroundColor(.secondary).font(.callout)
                            }
                            ForEach(notebooksManager.notebooks.prefix(5)) { notebook in
                                NavigationLink(destination: NotebookDetailView(notebook: notebook)) {
                                    DashboardCard(title: notebook.name, subtitle: "\(notebook.folders.count) folders", icon: "book.closed.fill", color: .indigo)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                dashboardSection(title: "Today's Tasks", icon: "checklist", color: .blue) {
                    VStack(spacing: 12) {
                        if tasksManager.todayTasks.isEmpty {
                            Text("All caught up!").foregroundColor(.secondary).font(.callout).padding(.vertical, 8)
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

                dashboardSection(title: "Latest Articles", icon: "newspaper.fill", color: .orange) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            if articlesManager.recentArticles.isEmpty {
                                Text("No recent articles").foregroundColor(.secondary).font(.callout)
                            }
                            ForEach(articlesManager.recentArticles.prefix(5)) { article in
                                NavigationLink(destination: ArticleDetailView(article: article)) {
                                    DashboardCard(title: article.title, subtitle: article.summary, icon: "doc.text.fill", color: .orange)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Workspace")
    }

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back,")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Jules's Workspace")
                .font(.title2.bold())
        }
        .padding(.horizontal)
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

struct WorkspaceMoreView: View {
    var body: some View {
        List {
            Section("Other Tools") {
                NavigationLink(destination: FormsView()) {
                    Label("Forms", systemImage: "list.bullet.rectangle.portrait")
                }
                NavigationLink(destination: SlidesHomeView()) {
                    Label("Slides", systemImage: "rectangle.on.rectangle.angled")
                }
                NavigationLink(destination: SpreadsheetsHomeView()) {
                    Label("Sheets", systemImage: "tablecells")
                }
            }
        }
        .navigationTitle("More")
    }
}
