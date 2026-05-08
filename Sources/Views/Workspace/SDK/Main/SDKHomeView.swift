import SwiftUI

struct SDKHomeView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var searchText = ""
    @State private var statusFilter: SDKProject.ProjectStatus?

    private var projects: [SDKProject] {
        projectManager.filteredProjects(search: searchText, status: statusFilter)
    }

    private let quickColumns = [GridItem(.flexible()), GridItem(.flexible())]

    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                Section {
                    LazyVGrid(columns: quickColumns, spacing: 10) {
                        quickTile("Build", subtitle: "Create and package", icon: "hammer.fill", color: .orange, value: SDKRoute.build)
                        quickTile("IDE", subtitle: "Edit and run", icon: "square.split.2x2.fill", color: .indigo, value: SDKRoute.ide)
                        quickTile("Debug", subtitle: "Diagnostics tools", icon: "ladybug.fill", color: .red, value: SDKRoute.debug)
                        quickTile("Docs", subtitle: "Guides and APIs", icon: "book.closed.fill", color: .blue, value: SDKRoute.docs)
                    }
                } header: {
                    SDKSectionHeader("Quick Start", subtitle: "Organized by workflow", systemImage: "sparkles")
                }
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
                    NavigationLink(value: SDKRoute.ide) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("IDE Workspace").font(.subheadline.bold())
                                Text("Multi panel runtime editor").font(.caption2).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "square.split.2x2.fill").foregroundStyle(.indigo)
                        }
                    }
                    NavigationLink(value: SDKRoute.docs) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Developer Guide").font(.subheadline.bold())
                                Text("Architecture & API documentation").font(.caption2).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "book.closed.fill").foregroundStyle(.blue)
                        }
                    }
                    NavigationLink(value: SDKRoute.build) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("App Builder").font(.subheadline.bold())
                                Text("Visual project configuration").font(.caption2).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "hammer.fill").foregroundStyle(.orange)
                        }
                    }
                    NavigationLink(value: SDKRoute.internal) {
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
            .navigationTitle("Workspace SDK")
            .navigationDestination(for: SDKRoute.self) { route in
                switch route {
                case .build: SDKBuildView()
                case .ide: SDKWorkspaceContainerView()
                case .debug: SDKDebugView()
                case .docs: SDKDeveloperGuideView()
                case .internal: SDKInternalView()
                case .project(let id):
                    SDKBuildView()
                        .onAppear { projectManager.loadProject(id: id) }
                }
            }
        .searchable(text: $searchText, prompt: "Search Projects")
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

    private enum SDKRoute: Hashable {
        case build
        case ide
        case debug
        case docs
        case `internal`
        case project(UUID)
    }

    private func quickTile(_ title: String, subtitle: String, icon: String, color: Color, value: SDKRoute) -> some View {
        NavigationLink(value: value) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func projectCard(_ project: SDKProject) -> some View {
        NavigationLink(value: SDKRoute.project(project.id)) {
            SDKModernCard(padding: 12) {
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
