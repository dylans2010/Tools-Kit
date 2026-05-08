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
                        projectCard(project)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
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
                SDKSectionHeader("SDK Projects", subtitle: "Managed workspace integrations and builds", systemImage: "folder.fill")
            }

            Section {
                NavigationLink(destination: SDKWorkspaceContainerView()) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("IDE Workspace").font(.subheadline.bold())
                            Text("Multi-panel runtime editor").font(.caption2).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "square.split.2x2.fill").foregroundStyle(.indigo)
                    }
                }
                NavigationLink(destination: SDKDeveloperGuideView()) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Developer Guide").font(.subheadline.bold())
                            Text("Architecture & API documentation").font(.caption2).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "book.closed.fill").foregroundStyle(.blue)
                    }
                }
                NavigationLink(destination: SDKBuildView()) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("App Builder").font(.subheadline.bold())
                            Text("Visual project configuration").font(.caption2).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "hammer.fill").foregroundStyle(.orange)
                    }
                }
                NavigationLink(destination: SDKInternalView()) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("SDK Internal").font(.subheadline.bold())
                            Text("Advanced system debugging").font(.caption2).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "terminal.fill").foregroundStyle(.primary)
                    }
                }
            } header: {
                SDKSectionHeader("Workspace", subtitle: "System-level development tools", systemImage: "square.grid.2x2.fill")
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

    @ViewBuilder
    private func projectCard(_ project: SDKProject) -> some View {
        NavigationLink {
            SDKBuildView()
                .onAppear { projectManager.loadProject(id: project.id) }
        } label: {
            SDKModernCard(padding: 12, content: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(project.name).font(.headline)
                        Spacer()
                        SDKStatusPill(
                            project.status.rawValue,
                            systemImage: project.status == .active ? "checkmark.circle.fill" : "pencil.circle",
                            color: project.status == .active ? .sdkSuccess : .sdkWarning
                        )
                    }

                    Text(project.description.isEmpty ? "No description provided for this SDK project." : project.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack {
                        Label("\(project.enabledScopes.count) Scopes", systemImage: "lock.shield")
                        Spacer()
                        Text("Updated \(project.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
