import SwiftUI

struct ProjectsMainView: View {
    @StateObject private var manager = ProjectsManager.shared
    @State private var searchText = ""
    @State private var statusFilter: ProjectStatus? = nil
    @State private var showCreateSheet = false
    @State private var sortByUpdated = true

    var filteredProjects: [Project] {
        var result = manager.projects
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let filter = statusFilter {
            result = result.filter { $0.status == filter }
        }
        return result
            .sorted { sortByUpdated ? $0.updatedAt > $1.updatedAt : $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            Group {
                if manager.projects.isEmpty {
                    emptyState
                } else {
                    projectList
                }
            }
            .navigationTitle("Projects")
            .searchable(text: $searchText, prompt: "Search projects")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("Sort: Recently Updated") { sortByUpdated = true }
                        Button("Sort: Name") { sortByUpdated = false }
                    } label: { Image(systemName: "arrow.up.arrow.down.circle") }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showCreateSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                ProjectCreateView { newProject in
                    manager.createProject(newProject)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("No Projects Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Create your first project to start organizing your work.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            Button("Create Project") { showCreateSheet = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var projectList: some View {
        VStack(spacing: 0) {
            HStack {
                StatPill(title: "Active", count: manager.activeProjects.count, color: .green)
                StatPill(title: "Completed", count: manager.completedProjects.count, color: .blue)
                StatPill(title: "Total", count: manager.projects.count, color: .secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            statusFilterPicker
            List {
                ForEach(filteredProjects) { project in
                    NavigationLink(destination: ProjectDetailsView(project: project)) {
                        ProjectRowView(project: project)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        manager.deleteProject(id: filteredProjects[index].id)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private var statusFilterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: statusFilter == nil) { statusFilter = nil }
                ForEach(ProjectStatus.allCases, id: \.self) { status in
                    FilterChip(title: status.rawValue, isSelected: statusFilter == status) {
                        statusFilter = statusFilter == status ? nil : status
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct StatPill: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)").font(.headline)
            Text(title).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(color.opacity(0.12))
        .cornerRadius(10)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct ProjectRowView: View {
    let project: Project

    var taskCount: Int { project.tasks.count }
    var doneCount: Int { project.tasks.filter { $0.status == .done }.count }
    var progress: Double {
        guard taskCount > 0 else { return 0 }
        return Double(doneCount) / Double(taskCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: project.colorHex) ?? .blue)
                        .frame(width: 44, height: 44)
                    Image(systemName: project.iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .lineLimit(1)
                    if !project.description.isEmpty {
                        Text(project.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                StatusBadge(status: project.status)
            }

            if taskCount > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Progress")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.caption2.bold())
                            .foregroundColor(.primary)
                    }

                    ProgressView(value: progress)
                        .tint(Color(hex: project.colorHex) ?? .blue)
                        .scaleEffect(x: 1, y: 0.5)
                }
            }

            HStack(spacing: 16) {
                Label("\(taskCount) tasks", systemImage: "checkmark.circle")
                Label("\(project.files.count) files", systemImage: "doc")
                if let nextTask = project.tasks.first(where: { $0.status != .done }), let dueDate = nextTask.dueDate {
                    Label(dueDate, style: .date)
                        .foregroundColor(.red)
                }
            }
            .font(.system(size: 10))
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct StatusBadge: View {
    let status: ProjectStatus

    var color: Color {
        switch status {
        case .active: return .green
        case .paused: return .orange
        case .completed: return .blue
        case .archived: return .gray
        }
    }

    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}
