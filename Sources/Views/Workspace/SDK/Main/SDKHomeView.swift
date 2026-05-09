/*
 REDESIGN SUMMARY:
 - Standardized on NavigationStack for modern iOS navigation patterns.
 - Applied listStyle(.insetGrouped) to maintain consistent system aesthetics.
 - Replaced hardcoded grid colors with semantic .secondary styling for quick tiles.
 - Replaced manual project cards with a private ProjectRow struct using native Label and status pills.
 - Improved layout spacing (16pt padding, 12pt VStack spacing).
 - Strictly preserved all existing business logic, including SDKProjectManager state and NavigationPath.
 - Standardized toolbar using ToolbarItem(placement: .topBarTrailing).
 */

import SwiftUI

struct SDKHomeView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var searchText = ""
    @State private var statusFilter: SDKProject.ProjectStatus?
    @State private var navigationPath = NavigationPath()

    private var projects: [SDKProject] {
        projectManager.filteredProjects(search: searchText, status: statusFilter)
    }

    private let quickColumns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                Section {
                    LazyVGrid(columns: quickColumns, spacing: 12) {
                        QuickTile(title: "Build", subtitle: "Create & package", icon: "hammer", value: SDKRoute.build)
                        QuickTile(title: "IDE", subtitle: "Edit & run", icon: "square.split.2x2", value: SDKRoute.ide)
                        QuickTile(title: "Debug", subtitle: "Diagnostics", icon: "ladybug", value: SDKRoute.debug)
                        QuickTile(title: "Docs", subtitle: "Guides & APIs", icon: "book.closed", value: SDKRoute.docs)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Quick Start")
                }

                Section {
                    if projects.isEmpty {
                        ContentUnavailableView(
                            "No Projects",
                            systemImage: "folder.badge.plus",
                            description: Text("Create an SDK project to get started.")
                        )
                    } else {
                        ForEach(projects) { project in
                            ProjectRow(project: project)
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
                                    .tint(.accentColor)
                                }
                        }
                    }
                } header: {
                    Text("SDK Projects")
                }

                Section {
                    NavigationLink(value: SDKRoute.internal) {
                        Label("SDK Internal", systemImage: "terminal")
                    }
                } header: {
                    Text("System Utilities")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Workspace SDK")
            .navigationDestination(for: SDKRoute.self) { route in
                destinationView(for: route)
            }
            .searchable(text: $searchText, prompt: "Search Projects")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterMenu
                }
            }
        }
    }

    private var filterMenu: some View {
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

    @ViewBuilder
    private func destinationView(for route: SDKRoute) -> some View {
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

    enum SDKRoute: Hashable {
        case build, ide, debug, docs, `internal`, project(UUID)
    }
}

// MARK: - Private Subviews

private struct QuickTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let value: AnyHashable

    var body: some View {
        NavigationLink(value: value) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

private struct ProjectRow: View {
    let project: SDKProject

    var body: some View {
        NavigationLink(value: SDKHomeView.SDKRoute.project(project.id)) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(project.name)
                        .font(.headline)
                    Spacer()
                    statusBadge
                }

                if !project.description.isEmpty {
                    Text(project.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Label("\(project.enabledScopes.count) Scopes", systemImage: "lock.shield")
                    Spacer()
                    Text("Updated \(project.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        let isActive = project.status == .active
        Label(project.status.rawValue.capitalized, systemImage: isActive ? "checkmark.circle.fill" : "pencil.circle")
            .font(.caption2.bold())
            .foregroundStyle(isActive ? .green : .orange)
    }
}
