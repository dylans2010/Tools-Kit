import SwiftUI

struct SDKHomeView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var searchText = ""
    @State private var statusFilter: SDKProject.ProjectStatus?

    private var projects: [SDKProject] {
        projectManager.filteredProjects(search: searchText, status: statusFilter)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Navigation") {
                    NavigationLink(destination: SDKBuildView()) {
                        Label("Build", systemImage: "hammer")
                    }
                    NavigationLink(destination: SDKWorkspaceContainerView()) {
                        Label("Editor", systemImage: "pencil.and.list.clipboard")
                    }
                    NavigationLink(destination: SDKDebugView()) {
                        Label("Diagnostics", systemImage: "stethoscope")
                    }
                    NavigationLink(destination: SDKDeveloperGuideView()) {
                        Label("Developer Guide", systemImage: "book")
                    }
                    NavigationLink(destination: SDKInternalView()) {
                        Label("Internal", systemImage: "gearshape.2")
                    }
                }

                Section("Projects") {
                    if projects.isEmpty {
                        ContentUnavailableView(
                            "No Projects",
                            systemImage: "folder.badge.plus",
                            description: Text("Create an SDK project to get started.")
                        )
                    } else {
                        ForEach(projects) { project in
                            NavigationLink {
                                SDKBuildView()
                                    .onAppear { projectManager.loadProject(id: project.id) }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(project.name)
                                        .font(.headline)
                                    Text(project.status.rawValue.capitalized)
                                        .font(.caption)
                                    if !project.description.isEmpty {
                                        Text(project.description)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                    Text("Updated \(project.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption2)
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
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workspace SDK")
            .searchable(text: $searchText, prompt: "Search Projects")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Status", selection: $statusFilter) {
                            Text("All").tag(Optional<SDKProject.ProjectStatus>.none)
                            Text("Active").tag(Optional(SDKProject.ProjectStatus.active))
                            Text("Draft").tag(Optional(SDKProject.ProjectStatus.draft))
                        }
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
}
