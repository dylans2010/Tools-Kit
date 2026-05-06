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
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @StateObject private var automationEngine = SDKAutomationEngine.shared
    @StateObject private var logStore = SDKLogStore.shared
    @State private var navPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navPath) {
            List {
                if let project = projectManager.currentProject {
                    projectMetadataCard(project)
                    controlHubSection
                } else {
                    Section {
                        ContentUnavailableView("No Project Found", systemImage: "folder.badge.plus", description: Text("Create a new project to get started."))
                    }
                }
            }
            .navigationTitle("SDK Dashboard")
            .navigationDestination(for: SDKRoute.self) { route in
                destinationView(for: route)
            }
            .onAppear {
                projectManager.updateHealth()
            }
        }
    }

    @ViewBuilder
    private func projectMetadataCard(_ project: SDKProject) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(project.name)
                        .font(.title2)
                        .bold()
                    Spacer()
                    healthBadge(project.healthStatus)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Label("Created: \(project.createdAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                    if let lastBuild = project.lastBuiltAt {
                        Label("Last Build: \(lastBuild.formatted(.relative(presentation: .numeric)))", systemImage: "hammer.fill")
                    } else {
                        Label("Not yet built", systemImage: "hammer")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var controlHubSection: some View {
        Section("Control Hub") {
            hubRow(route: .build, title: "Build & Export", subtitle: buildSubtitle, icon: "hammer", color: .blue, status: .connected)
            hubRow(route: .connectors, title: "Connectors", subtitle: "\(connectorManager.connectors.count) active", icon: "link", color: .green, status: connectorManager.connectors.isEmpty ? .disconnected : .connected)
            hubRow(route: .automation, title: "Automation", subtitle: "\(automationEngine.rules.count) rules", icon: "bolt.fill", color: .orange, status: .connected)
            hubRow(route: .plugins, title: "Plugins", subtitle: "Expand capabilities", icon: "puzzlepiece.fill", color: .purple, status: .connected)
            hubRow(route: .tools, title: "Tools", subtitle: "Data utilities", icon: "wrench.and.screwdriver.fill", color: .gray, status: .connected)
            hubRow(route: .appBuilder, title: "App Builder", subtitle: "Visual editor", icon: "wand.and.stars", color: .indigo, status: .connected)
            hubRow(route: .logs, title: "System Logs", subtitle: "\(logStore.entries.count) events", icon: "terminal.fill", color: .black, status: .connected)
            hubRow(route: .diagnostics, title: "Diagnostics", subtitle: "System health", icon: "heart.text.square.fill", color: .red, status: .connected)
        }
    }

    private var buildSubtitle: String {
        if let last = projectManager.currentProject?.lastBuiltAt {
            return "Last build: \(last.formatted(.relative(presentation: .numeric)))"
        }
        return "Not built yet"
    }

    private func hubRow(route: SDKRoute, title: String, subtitle: String, icon: String, color: Color, status: ConnectorStatus) -> some View {
        Button {
            navPath.append(route)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(color, in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Circle()
                    .fill(statusColor(status))
                    .frame(width: 8, height: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 2)
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
    private func destinationView(for route: SDKRoute) -> some View {
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
}
