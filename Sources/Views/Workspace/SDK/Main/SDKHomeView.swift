import SwiftUI

struct SDKHomeView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @StateObject private var pluginManager = SDKPluginManager.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared
    @State private var searchText = ""
    @State private var statusFilter: SDKProject.ProjectStatus?
    @State private var showingSystemStatus = false
    @State private var showingQuickActions = false

    private var projects: [SDKProject] {
        projectManager.filteredProjects(search: searchText, status: statusFilter)
    }

    var body: some View {
        List {
            systemOverviewSection

            Section {
                NavigationLink(destination: SignInView()) {
                    Label("Authorization", systemImage: "lock.shield")
                }
                NavigationLink(destination: PluginsMainView()) {
                    Label("Plugins", systemImage: "puzzlepiece")
                }
                NavigationLink(destination: ConnectorsMainView()) {
                    Label("Connectors", systemImage: "link")
                }
            } header: {
                SDKSectionHeader("Core Services", subtitle: "Authentication, plugins, and connectors.", alignment: .leading)
            }

            Section {
                NavigationLink(destination: SDKBuildView()) {
                    Label("App Builder", systemImage: "hammer")
                }
                NavigationLink(destination: SDKWorkspaceContainerView()) {
                    Label("Editor", systemImage: "pencil.and.list.clipboard")
                }
                NavigationLink(destination: SDKDebugView()) {
                    Label("Diagnostics", systemImage: "stethoscope")
                }
                NavigationLink(destination: SDKDeveloperGuideView()) {
                    Label("Documentation", systemImage: "book")
                }
                NavigationLink(destination: SDKInternalView()) {
                    Label("Internal Tools", systemImage: "gearshape.2")
                }
            } header: {
                SDKSectionHeader("Development", subtitle: "Build, debug, and explore the SDK", alignment: .leading)
            }

            quickActionsSection

            Section {
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
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(project.name).font(.headline)
                                    HStack(spacing: 6) {
                                        Text(project.status.rawValue.capitalized)
                                            .font(.caption2.weight(.medium))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(statusColor(project.status).opacity(0.15), in: Capsule())
                                            .foregroundStyle(statusColor(project.status))
                                        if !project.description.isEmpty {
                                            Text(project.description)
                                                .font(.caption)
                                                .lineLimit(1)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Text("Updated \(project.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
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
            } header: {
                SDKSectionHeader("Projects", subtitle: "\(projects.count) Project\(projects.count == 1 ? "" : "s")", alignment: .leading)
            }
        }
        .listStyle(.insetGrouped)
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
                        Label("New Project", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - System Overview Section

    private var systemOverviewSection: some View {
        Section {
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(projects.count)").font(.title3.bold()).foregroundStyle(.blue)
                    Text("Projects").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    Text("\(connectorManager.connectors.filter { $0.isConnected }.count)").font(.title3.bold()).foregroundStyle(.green)
                    Text("Connected").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    Text("\(pluginManager.plugins.filter(\.isEnabled).count)").font(.title3.bold()).foregroundStyle(.purple)
                    Text("Plugins").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    let metrics = telemetry.getMetrics()
                    let rate = metrics.totalTraces > 0 ? Int(Double(metrics.successCount) / Double(metrics.totalTraces) * 100) : 100
                    Text("\(rate)%").font(.title3.bold()).foregroundStyle(rate >= 95 ? .green : rate >= 80 ? .orange : .red)
                    Text("Health").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        } header: {
            SDKSectionHeader("System Status", subtitle: "Real-time workspace overview", alignment: .leading)
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        Section {
            Button {
                _ = projectManager.createProject(name: "New SDK Project", status: .draft)
            } label: {
                Label("Create New Project", systemImage: "plus.rectangle")
            }
            NavigationLink(destination: SDKDiagnosticsView()) {
                Label("Run Diagnostics", systemImage: "stethoscope")
            }
            NavigationLink(destination: SDKAPIExplorerView()) {
                Label("API Explorer", systemImage: "point.3.connected.trianglepath.dotted")
            }
            NavigationLink(destination: SDKDataInspectorView()) {
                Label("Data Inspector", systemImage: "magnifyingglass")
            }
            NavigationLink(destination: SDKAutomationView()) {
                Label("Automation", systemImage: "bolt")
            }
        } header: {
            SDKSectionHeader("Quick Actions", subtitle: "Frequently Used Tools", alignment: .leading)
        }
    }

    private func statusColor(_ status: SDKProject.ProjectStatus) -> Color {
        switch status {
        case .active: return .green
        case .draft: return .orange
        case .archived: return .secondary
        }
    }
}
