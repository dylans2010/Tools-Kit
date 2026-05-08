import SwiftUI

struct SDKHomeView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var searchText = ""
    @State private var statusFilter: SDKProject.ProjectStatus?

    private var projects: [SDKProject] {
        projectManager.filteredProjects(search: searchText, status: statusFilter)
    }

    var body: some View {
        List {
            Section {
                if projects.isEmpty {
                    ContentUnavailableView(
                        "No Projects",
                        systemImage: "folder.badge.plus",
                        description: Text("Create a project in App Builder to get started.")
                    )
                } else {
                    ForEach(projects) { project in
                        NavigationLink {
                            SDKBuildView()
                                .onAppear { projectManager.loadProject(id: project.id) }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(project.name).font(.headline)
                                    Spacer()
                                    Text(project.status.rawValue.capitalized)
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background((project.status == .active ? Color.green : Color.orange).opacity(0.2), in: Capsule())
                                }
                                Text(project.description.isEmpty ? "No description" : project.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Text("Updated \(project.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                    Spacer()
                                    Text("Scopes: \(project.enabledScopes.count)")
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                projectManager.deleteProject(id: project.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                _ = projectManager.duplicateProject(id: project.id)
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            .tint(.blue)
                        }
                    }
                }
            } header: {
                Text("SDK Projects")
            }

            Section {
                NavigationLink(destination: SDKDeveloperGuideView()) {
                    Label("Developer Guide", systemImage: "book.closed.fill")
                }
                NavigationLink(destination: SDKBuildView()) {
                    Label("App Builder", systemImage: "hammer.fill")
                }
                NavigationLink(destination: SDKInternalView()) {
                    Label("SDK Internal", systemImage: "terminal.fill")
                }
            } header: {
                Text("Workspace")
            }
        }
        .navigationTitle("WorkspaceSDK")
        .searchable(text: $searchText, prompt: "Search projects")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("All") { statusFilter = nil }
                    Button("Active") { statusFilter = .active }
                    Button("Draft") { statusFilter = .draft }
                    Divider()
                    Button {
                        _ = projectManager.createProject(name: "New SDK Project", status: .draft)
                    } label: {
                        Label("Create Project", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
}
