import SwiftUI

enum SDKRoute: Hashable {
    case build
    case connectors
    case automation
    case logs
    case diagnostics
    case plugins
    case tools
    case appBuilder
}

struct SDKProjectDashboardView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var backgroundEngine = SDKBackgroundEngine.shared
    @State private var navPath = NavigationPath()
    @Binding var selectedProject: SDKProject?

    var body: some View {
        NavigationStack(path: $navPath) {
            List {
                if let project = projectManager.currentProject {
                    Section {
                        ProjectMetadataCard(project: project)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("Control Hub") {
                    ControlHubRow(route: .build, title: "Build", subtitle: "Project Editor", icon: "hammer.fill", status: .healthy)
                    ControlHubRow(route: .connectors, title: "Connectors", subtitle: "\(SDKConnectorManager.shared.connectors.count) connectors active", icon: "link", status: backgroundEngine.systemHealth.overallStatus)
                    ControlHubRow(route: .plugins, title: "Plugins", subtitle: "\(SDKPluginManager.shared.plugins.count) plugins installed", icon: "puzzlepiece.fill", status: .healthy)
                    ControlHubRow(route: .tools, title: "Tools", subtitle: "\(SDKToolManager.shared.tools.count) tools available", icon: "wrench.adjustable.fill", status: .healthy)
                    ControlHubRow(route: .automation, title: "Automation", subtitle: "\(SDKAutomationEngine.shared.rules.count) rules active", icon: "bolt.fill", status: .healthy)
                    ControlHubRow(route: .logs, title: "Logs", subtitle: "System events", icon: "terminal.fill", status: .healthy)
                    ControlHubRow(route: .diagnostics, title: "Diagnostics", subtitle: "System health", icon: "heart.text.square.fill", status: backgroundEngine.systemHealth.overallStatus)
                    ControlHubRow(route: .appBuilder, title: "App Builder", subtitle: "Create custom app", icon: "square.stack.3d.up.fill", status: .healthy)
                }

                Section("Projects") {
                    if projectManager.savedProjects.isEmpty {
                        Text("No projects yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(projectManager.savedProjects) { project in
                            Button {
                                projectManager.currentProject = project
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(project.name).font(.headline)
                                        Text(project.status.rawValue.capitalized)
                                            .font(.caption)
                                            .foregroundStyle(project.status == .running ? .green : .secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("SDK Dashboard")
            .navigationDestination(for: SDKRoute.self) { route in
                switch route {
                case .build: SDKBuildView()
                case .connectors: SDKConnectorsView()
                case .automation: SDKAutomationView()
                case .logs: SDKLogsView()
                case .diagnostics: SDKDiagnosticsView()
                case .plugins: SDKPluginsView()
                case .tools: SDKToolsView()
                case .appBuilder: SDKAppBuilderView()
                }
            }
            .onAppear {
                projectManager.updateHealth()
            }
        }
    }

    @ViewBuilder
    private func ControlHubRow(route: SDKRoute, title: String, subtitle: String, icon: String, status: HealthStatus) -> some View {
        NavigationLink(value: route) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }

                Spacer()

                Circle()
                    .fill(statusColor(status))
                    .frame(width: 8, height: 8)
            }
            .padding(.vertical, 4)
        }
    }

    private func statusColor(_ status: HealthStatus) -> Color {
        switch status {
        case .healthy: return .green
        case .degraded: return .yellow
        case .critical: return .red
        case .unknown: return .gray
        }
    }
}

struct ProjectMetadataCard: View {
    let project: SDKProject

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.title2)
                        .bold()
                    Text("Created \(project.createdAt, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HealthBadge(status: project.healthStatus)
            }

            Divider()

            HStack(spacing: 20) {
                MetadataItem(label: "Last Build", value: project.lastBuiltAt?.formatted(date: .abbreviated, time: .shortened) ?? "Never")
                MetadataItem(label: "Scopes", value: "\(project.enabledScopes.count)")
                MetadataItem(label: "Status", value: project.status.rawValue.capitalized)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct HealthBadge: View {
    let status: HealthStatus
    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.caption2)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .cornerRadius(8)
    }

    var statusColor: Color {
        switch status {
        case .healthy: return .green
        case .degraded: return .yellow
        case .critical: return .red
        case .unknown: return .gray
        }
    }
}

struct MetadataItem: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.caption).bold()
        }
    }
}
