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

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack(path: $navPath) {
            ScrollView {
                VStack(spacing: 24) {
                    if let project = projectManager.currentProject {
                        projectHeader(project)

                        SDKSectionHeader(title: "Control Hub", subtext: "Integrated tools and runtime management.")

                        LazyVGrid(columns: columns, spacing: 16) {
                            hubCard(route: .build, title: "Build", subtitle: "Export & Build", icon: "hammer.fill", color: .blue)
                            hubCard(route: .ideWorkspace, title: "IDE", subtitle: "Runtime Editor", icon: "square.split.2x2.fill", color: .indigo)
                            hubCard(route: .connectors, title: "Connect", subtitle: "\(connectorManager.connectors.count) Active", icon: "link", color: .green)
                            hubCard(route: .automation, title: "Rules", subtitle: "\(automationEngine.rules.count) Rules", icon: "bolt.fill", color: .orange)
                            hubCard(route: .plugins, title: "Plugins", subtitle: "Capabilities", icon: "puzzlepiece.fill", color: .purple)
                            hubCard(route: .tools, title: "Tools", subtitle: "Utilities", icon: "wrench.and.screwdriver.fill", color: .gray)
                            hubCard(route: .appBuilder, title: "Designer", subtitle: "Visual Editor", icon: "wand.and.stars", color: .indigo)
                            hubCard(route: .logs, title: "Logs", subtitle: "\(logStore.entries.count) Entries", icon: "terminal.fill", color: .black)
                        }

                        SDKSectionHeader(title: "Diagnostics", subtext: "System health and status.")

                        SDKModernCard {
                            NavigationLink(value: SDKDashboardRoute.diagnostics) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("System Health").font(.subheadline.bold())
                                        Text("View detailed diagnostics").sdkSubtext()
                                    }
                                    Spacer()
                                    SDKStatusPill(status: project.healthStatus.toSDKStatus(), text: project.healthStatus.rawValue.uppercased())
                                    Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        ContentUnavailableView(
                            "No Project Found",
                            systemImage: "folder.badge.plus",
                            description: Text("Create a new project to get started.")
                        )
                        .padding(.top, 40)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("SDK Dashboard")
            .navigationDestination(for: SDKDashboardRoute.self) { route in
                destinationView(for: route)
            }
            .onAppear {
                projectManager.updateHealth()
            }
        }
    }

    private func projectHeader(_ project: SDKProject) -> some View {
        SDKModernCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.title2.bold())
                        Text("v\(project.version)")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    SDKStatusPill(status: project.healthStatus.toSDKStatus(), text: project.healthStatus.rawValue.uppercased())
                }

                Divider()

                HStack(spacing: 20) {
                    statItem(label: "Scopes", value: "\(project.enabledScopes.count)")
                    statItem(label: "Plugins", value: "\(project.enabledPluginIDs.count)")
                    statItem(label: "Tools", value: "\(project.enabledToolIDs.count)")
                }

                if let lastBuild = project.lastBuiltAt {
                    Text("Last Build: \(lastBuild.formatted(.relative(presentation: .numeric)))")
                        .sdkSubtext()
                }
            }
        }
    }

    private func hubCard(route: SDKDashboardRoute, title: String, subtitle: String, icon: String, color: Color) -> some View {
        Button {
            navPath.append(route)
        } label: {
            SDKModernCard {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(color.gradient, in: RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.headline)
                        Text(subtitle).sdkSubtext()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundStyle(.secondary)
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

extension HealthStatus {
    func toSDKStatus() -> SDKStatus {
        switch self {
        case .healthy: return .success
        case .degraded: return .warning
        case .critical: return .error
        case .unknown: return .info
        }
    }
}
