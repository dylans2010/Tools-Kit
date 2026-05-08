import SwiftUI

enum SDKDashboardRoute: Hashable {
    case ideWorkspace
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
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @StateObject private var automationEngine = SDKAutomationEngine.shared
    @StateObject private var logStore = SDKLogStore.shared
    @State private var navPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navPath) {
            List {
                if let project = projectManager.currentProject {
                    Section {
                        projectMetadataCard(project)
                    } header: {
                        SDKSectionHeader("Project Overview", subtitle: "Active configuration and health status", systemImage: "info.circle")
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                    Section {
                        controlHubSection
                    } header: {
                        SDKSectionHeader("Control Hub", subtitle: "Centralized SDK management and tools", systemImage: "square.grid.3x3.fill")
                    }
                } else {
                    Section {
                        ContentUnavailableView("No Project Found", systemImage: "folder.badge.plus", description: Text("Create a new project to get started."))
                    }
                }
            }
            .navigationTitle("SDK Dashboard")
            .navigationDestination(for: SDKDashboardRoute.self) { route in
                destinationView(for: route)
            }
            .onAppear {
                projectManager.updateHealth()
            }
        }
    }

    @ViewBuilder
    private func projectMetadataCard(_ project: SDKProject) -> some View {
        SDKModernCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.title3.bold())
                        Text("v\(project.version)")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    healthBadge(project.healthStatus)
                }

                Divider().opacity(0.5)

                VStack(alignment: .leading, spacing: 6) {
                    Label("Created: \(project.createdAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                    if let lastBuild = project.lastBuiltAt {
                        Label("Last Build: \(lastBuild.formatted(.relative(presentation: .numeric)))", systemImage: "hammer.fill")
                    } else {
                        Label("Not Yet Built", systemImage: "hammer")
                    }
                    Label("\(project.enabledScopes.count) Scopes Enabled", systemImage: "lock.shield")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var controlHubSection: some View {
        Group {
            hubRow(route: .build, title: "Build & Export", subtitle: buildSubtitle, icon: "hammer", color: .blue, status: .connected)
            hubRow(route: .ideWorkspace, title: "IDE Workspace", subtitle: "Multi-panel runtime editor", icon: "square.split.2x2.fill", color: .indigo, status: .connected)
            hubRow(route: .connectors, title: "Connectors", subtitle: "\(connectorManager.connectors.count) active modules", icon: "link", color: .green, status: connectorManager.connectors.isEmpty ? .disconnected : .connected)
            hubRow(route: .automation, title: "Automation", subtitle: "\(automationEngine.rules.count) active rules", icon: "bolt.fill", color: .orange, status: .connected)
            hubRow(route: .plugins, title: "Plugins", subtitle: "Capability expansion packs", icon: "puzzlepiece.fill", color: .purple, status: .connected)
            hubRow(route: .tools, title: "Tools", subtitle: "Advanced data utilities", icon: "wrench.and.screwdriver.fill", color: .gray, status: .connected)
            hubRow(route: .appBuilder, title: "App Builder", subtitle: "Visual integration editor", icon: "wand.and.stars", color: .indigo, status: .connected)
            hubRow(route: .logs, title: "System Logs", subtitle: "\(logStore.entries.count) stored events", icon: "terminal.fill", color: .black, status: .connected)
            hubRow(route: .diagnostics, title: "Diagnostics", subtitle: "Real-time system health", icon: "heart.text.square.fill", color: .red, status: .connected)
        }
    }

    private var buildSubtitle: String {
        if let last = projectManager.currentProject?.lastBuiltAt {
            return "Last Build: \(last.formatted(.relative(presentation: .numeric)))"
        }
        return "Not Built Yet"
    }

    private func hubRow(route: SDKDashboardRoute, title: String, subtitle: String, icon: String, color: Color, status: ConnectorStatus) -> some View {
        Button {
            navPath.append(route)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(color.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                SDKStatusPill(
                    status == .connected ? "Ready" : "Offline",
                    color: statusColor(status),
                    isCapsule: false
                )

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func healthBadge(_ status: HealthStatus) -> some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.2), in: Capsule())
            .foregroundStyle(statusColor(status))
    }

    private func statusColor(_ status: HealthStatus) -> Color {
        switch status {
        case .healthy: return .green
        case .degraded: return .yellow
        case .critical: return .red
        case .unknown: return .gray
        }
    }

    private func statusColor(_ status: ConnectorStatus) -> Color {
        switch status {
        case .connected: return .green
        case .connecting: return .yellow
        case .error: return .red
        case .disconnected: return .gray
        }
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
