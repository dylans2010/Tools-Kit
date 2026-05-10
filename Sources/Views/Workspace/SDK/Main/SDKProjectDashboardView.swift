

import SwiftUI

struct SDKProjectDashboardView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @StateObject private var automationEngine = SDKAutomationEngine.shared
    @StateObject private var logStore = SDKLogStore.shared
    @State private var navPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navPath) {
            List {
                if let project = projectManager.currentProject {
                    Section {
                        MetadataHeader(project: project)
                    } header: {
                        Text("Overview")
                    }

                    Section("Control Hub") {
                        HubLink(route: .build, title: "Build & Export", subtitle: buildSubtitle, icon: "hammer", color: .blue)
                        HubLink(route: .ideWorkspace, title: "IDE Workspace", subtitle: "Multi-panel runtime editor", icon: "square.split.2x2", color: .indigo)
                        HubLink(route: .connectors, title: "Connectors", subtitle: "\(connectorManager.connectors.count) active modules", icon: "link", color: .green)
                        HubLink(route: .automation, title: "Automation", subtitle: "\(automationEngine.rules.count) active rules", icon: "bolt", color: .orange)
                        HubLink(route: .plugins, title: "Plugins", subtitle: "Capability expansion", icon: "puzzlepiece", color: .purple)
                        HubLink(route: .appBuilder, title: "App Builder", subtitle: "Visual integration", icon: "wand.and.stars", color: .indigo)
                    }

                    Section("System") {
                        HubLink(route: .logs, title: "System Logs", subtitle: "\(logStore.entries.count) stored events", icon: "terminal", color: .primary)
                        HubLink(route: .diagnostics, title: "Diagnostics", subtitle: "Real-time health", icon: "heart.text.square", color: .red)
                    }
                } else {
                    ContentUnavailableView("No Project Found", systemImage: "folder.badge.plus", description: Text("Select or create a project in the Build tab."))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Dashboard")
            .navigationDestination(for: SDKDashboardRoute.self) { route in
                destinationView(for: route)
            }
            .onAppear {
                projectManager.updateHealth()
            }
        }
    }

    private var buildSubtitle: String {
        if let last = projectManager.currentProject?.lastBuiltAt {
            return "Last Built: \(last.formatted(.relative(presentation: .numeric)))"
        }
        return "Not Built Yet"
    }

    @ViewBuilder
    private func destinationView(for route: SDKDashboardRoute) -> some View {
        switch route {
        case .ideWorkspace: SDKWorkspaceContainerView()
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
}

// MARK: - Private Subviews

private struct MetadataHeader: View {
    let project: SDKProject

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name).font(.title3.bold())
                    Text("v\(project.version)").font(.caption2.monospaced()).foregroundStyle(.tertiary)
                }
                Spacer()
                HealthBadge(status: project.healthStatus)
            }

            VStack(alignment: .leading, spacing: 6) {
                Label("Created: \(project.createdAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                Label("\(project.enabledScopes.count) Scopes Enabled", systemImage: "lock.shield")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct HealthBadge: View {
    let status: HealthStatus
    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1), in: Capsule())
            .foregroundStyle(color)
    }
    private var color: Color {
        switch status {
        case .healthy: return .green
        case .degraded: return .yellow
        case .critical: return .red
        case .unknown: return .gray
        }
    }
}

private struct HubLink: View {
    let route: SDKDashboardRoute
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        NavigationLink(value: route) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.bold())
                    Text(subtitle).font(.caption2).foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: icon).foregroundStyle(color)
            }
        }
    }
}

enum SDKDashboardRoute: Hashable {
    case ideWorkspace, build, connectors, automation, logs, diagnostics, plugins, tools, appBuilder
}
